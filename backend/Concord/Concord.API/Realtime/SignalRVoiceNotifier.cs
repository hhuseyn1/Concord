using Concord.API.Hubs;
using Concord.Application.Realtime;
using Microsoft.AspNetCore.SignalR;

namespace Concord.API.Realtime;

public class SignalRVoiceNotifier(IHubContext<VoiceHub> voiceHubContext, IHubContext<DirectMessagesHub> directMessagesHubContext) : IVoiceRealtimeNotifier
{
    private readonly IHubContext<VoiceHub> _voiceHubContext = voiceHubContext;
    private readonly IHubContext<DirectMessagesHub> _directMessagesHubContext = directMessagesHubContext;

    public async Task VoiceParticipantJoinedAsync(Guid channelId, Guid userId)
    {
        await _voiceHubContext.Clients.Group($"Channel:{channelId}").SendAsync("VoiceParticipantJoined", new { channelId, userId });
    }

    public async Task VoiceParticipantLeftAsync(Guid channelId, Guid userId)
    {
        await _voiceHubContext.Clients.Group($"Channel:{channelId}").SendAsync("VoiceParticipantLeft", new { channelId, userId });
    }

    public async Task DirectCallParticipantJoinedAsync(Guid userAId, Guid userBId, Guid conversationId, Guid userId)
    {
        await _directMessagesHubContext.Clients.Users([userAId.ToString(), userBId.ToString()])
            .SendAsync("DirectCallParticipantJoined", new { conversationId, userId });
    }

    public async Task DirectCallParticipantLeftAsync(Guid userAId, Guid userBId, Guid conversationId, Guid userId)
    {
        await _directMessagesHubContext.Clients.Users([userAId.ToString(), userBId.ToString()])
            .SendAsync("DirectCallParticipantLeft", new { conversationId, userId });
    }
}
