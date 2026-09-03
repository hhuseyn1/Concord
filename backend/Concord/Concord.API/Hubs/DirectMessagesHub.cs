using System.IdentityModel.Tokens.Jwt;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Concord.API.Hubs;

// No groups for message delivery: a DM is always exactly 2 participants, so the controller pushes
// directly via Clients.Users([...]) (same targeted-push pattern PresenceHub/NotificationsHub use)
// rather than a per-conversation group like MessagesHub's Channel:{channelId}. Typing (M-03) is the
// one thing this hub does itself rather than leaving to a controller, since it has no REST action to
// piggyback on - it needs to resolve the other participant to target the push at.
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

    /// <summary>Explicit "I stopped typing" (P1.3) - sent on successful message send or on leaving the conversation.</summary>
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
