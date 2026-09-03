using Concord.Application.Models;

namespace Concord.Application.Realtime;

public interface IServersRealtimeNotifier
{
    Task ServerUpdatedAsync(Guid serverId, ServerResponse server);
    Task ServerMemberJoinedAsync(Guid serverId, Guid userId);
    Task ServerMemberLeftAsync(Guid serverId, Guid userId);
    Task RemovedFromServerAsync(Guid userId, Guid serverId);

    /// <summary>P1: the caller's own moderation state changed - their client must re-resolve its
    /// permissions, since a mute or timeout silently subtracts from them.</summary>
    Task ServerModerationChangedAsync(Guid serverId, Guid targetUserId);
    Task ChannelCreatedAsync(Guid serverId, ChannelResponse channel);
    Task ChannelUpdatedAsync(Guid serverId, ChannelResponse channel);
    Task ChannelDeletedAsync(Guid serverId, Guid channelId);
}
