using System.IdentityModel.Tokens.Jwt;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Concord.API.Hubs;

[Authorize]
public class DirectMessagesHub(DirectMessagesService directMessagesService) : Hub
{
    private readonly DirectMessagesService _directMessagesService = directMessagesService;

    public async Task Typing(Guid conversationId)
    {
        var otherUserId = await ResolveOtherParticipantAsync(conversationId);
        if (otherUserId is null)
            return;

        var userId = await GetCallerUserIdAsync();
        await Clients.User(otherUserId.Value.ToString()).SendAsync("UserTyping", new { conversationId, userId });
    }

    public async Task StopTyping(Guid conversationId)
    {
        var otherUserId = await ResolveOtherParticipantAsync(conversationId);
        if (otherUserId is null)
            return;

        var userId = await GetCallerUserIdAsync();
        await Clients.User(otherUserId.Value.ToString()).SendAsync("UserStoppedTyping", new { conversationId, userId });
    }

    private Task<Guid?> GetCallerUserIdAsync()
    {
        var claimedUserId = Context.User?.Claims.FirstOrDefault(claim => claim.Type == JwtRegisteredClaimNames.Sub)?.Value;
        return Task.FromResult(Guid.TryParse(claimedUserId, out Guid userId) ? userId : (Guid?)null);
    }

    private async Task<Guid?> ResolveOtherParticipantAsync(Guid conversationId)
    {
        var userId = await GetCallerUserIdAsync();
        if (userId is null)
            return null;

        (Guid UserAId, Guid UserBId) participants;
        try
        {
            participants = await _directMessagesService.GetConversationParticipantsAsync(conversationId);
        }
        catch
        {
            return null;
        }

        if (participants.UserAId != userId && participants.UserBId != userId)
            return null;

        return participants.UserAId == userId ? participants.UserBId : participants.UserAId;
    }
}
