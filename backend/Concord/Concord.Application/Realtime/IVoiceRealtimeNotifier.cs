namespace Concord.Application.Realtime;

public interface IVoiceRealtimeNotifier
{
    Task VoiceParticipantJoinedAsync(Guid channelId, Guid userId);
    Task VoiceParticipantLeftAsync(Guid channelId, Guid userId);
    Task DirectCallParticipantJoinedAsync(Guid userAId, Guid userBId, Guid conversationId, Guid userId);
    Task DirectCallParticipantLeftAsync(Guid userAId, Guid userBId, Guid conversationId, Guid userId);
}
