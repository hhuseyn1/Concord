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

    /// <summary>
    /// Ephemeral typing signal (M-03) - no persistence. The recipient side also expires the indicator
    /// locally after a short timeout since the last event, as a safety net for a sender's client
    /// closing mid-type without ever calling <see cref="StopTyping"/>. Only reaches whoever is already
    /// in the group (i.e. already joined via <see cref="JoinChannel"/>), so no separate membership
    /// check here.
    /// </summary>
    public async Task Typing(Guid channelId)
    {
        var claimedUserId = Context.User?.Claims.FirstOrDefault(claim => claim.Type == JwtRegisteredClaimNames.Sub)?.Value;
        if (!Guid.TryParse(claimedUserId, out Guid userId))
            return;

        await Clients.OthersInGroup($"Channel:{channelId}").SendAsync("UserTyping", new { channelId, userId });
    }

    /// <summary>Explicit "I stopped typing" (P1.3) - sent on successful message send or on leaving the channel, so the indicator clears immediately instead of waiting out the client-side timeout.</summary>
    public async Task StopTyping(Guid channelId)
    {
        var claimedUserId = Context.User?.Claims.FirstOrDefault(claim => claim.Type == JwtRegisteredClaimNames.Sub)?.Value;
        if (!Guid.TryParse(claimedUserId, out Guid userId))
            return;

        await Clients.OthersInGroup($"Channel:{channelId}").SendAsync("UserStoppedTyping", new { channelId, userId });
    }
}
