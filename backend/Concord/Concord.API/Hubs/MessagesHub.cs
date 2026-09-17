using System.IdentityModel.Tokens.Jwt;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Concord.API.Hubs;

[Authorize]
public class MessagesHub(ChannelsService channelsService) : Hub
{
    private readonly ChannelsService _channelsService = channelsService;

    public async Task JoinChannel(Guid channelId)
    {
        try
        {
            var claimedUserId = Context.User?.Claims.FirstOrDefault(claim => claim.Type == JwtRegisteredClaimNames.Sub)?.Value;
            var userId = Guid.TryParse(claimedUserId, out Guid parsedUserId) ? parsedUserId : throw new UnauthorizedAccessException();

            await _channelsService.AssertChannelMemberAsync(userId, channelId);

            await Groups.AddToGroupAsync(Context.ConnectionId, $"Channel:{channelId}");
        }
        catch (Exception ex)
        {
            throw new HubException(ex.Message);
        }
    }

    public async Task LeaveChannel(Guid channelId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Channel:{channelId}");
    }

    public async Task Typing(Guid channelId)
    {
        var claimedUserId = Context.User?.Claims.FirstOrDefault(claim => claim.Type == JwtRegisteredClaimNames.Sub)?.Value;
        if (!Guid.TryParse(claimedUserId, out Guid userId))
            return;

        await Clients.OthersInGroup($"Channel:{channelId}").SendAsync("UserTyping", new { channelId, userId });
    }

    public async Task StopTyping(Guid channelId)
    {
        var claimedUserId = Context.User?.Claims.FirstOrDefault(claim => claim.Type == JwtRegisteredClaimNames.Sub)?.Value;
        if (!Guid.TryParse(claimedUserId, out Guid userId))
            return;

        await Clients.OthersInGroup($"Channel:{channelId}").SendAsync("UserStoppedTyping", new { channelId, userId });
    }
}
