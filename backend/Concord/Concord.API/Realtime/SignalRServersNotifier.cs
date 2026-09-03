using Concord.API.Hubs;
using Concord.Application.Models;
using Concord.Application.Realtime;
using Microsoft.AspNetCore.SignalR;

namespace Concord.API.Realtime;

public class SignalRServersNotifier(IHubContext<ServersHub> hubContext) : IServersRealtimeNotifier
{
    private readonly IHubContext<ServersHub> _hubContext = hubContext;

    public async Task ServerUpdatedAsync(Guid serverId, ServerResponse server)
    {
        await _hubContext.Clients.Group($"Server:{serverId}").SendAsync("ServerUpdated", server);
    }

    public async Task ServerMemberJoinedAsync(Guid serverId, Guid userId)
    {
        await _hubContext.Clients.Group($"Server:{serverId}").SendAsync("ServerMemberJoined", new { serverId, userId });
    }

    public async Task ServerMemberLeftAsync(Guid serverId, Guid userId)
    {
        await _hubContext.Clients.Group($"Server:{serverId}").SendAsync("ServerMemberLeft", new { serverId, userId });
    }

    public async Task RemovedFromServerAsync(Guid userId, Guid serverId)
    {
        await _hubContext.Clients.User(userId.ToString()).SendAsync("RemovedFromServer", new { serverId });
    }

    public async Task ServerModerationChangedAsync(Guid serverId, Guid targetUserId)
    {
        await _hubContext.Clients.Group($"Server:{serverId}").SendAsync("ServerModerationChanged", new { serverId, targetUserId });
        await _hubContext.Clients.User(targetUserId.ToString()).SendAsync("ServerModerationChanged", new { serverId, targetUserId });
    }

    public async Task ChannelCreatedAsync(Guid serverId, ChannelResponse channel)
    {
        await _hubContext.Clients.Group($"Server:{serverId}").SendAsync("ChannelCreated", channel);
    }

    public async Task ChannelUpdatedAsync(Guid serverId, ChannelResponse channel)
    {
        await _hubContext.Clients.Group($"Server:{serverId}").SendAsync("ChannelUpdated", channel);
    }

    public async Task ChannelDeletedAsync(Guid serverId, Guid channelId)
    {
        await _hubContext.Clients.Group($"Server:{serverId}").SendAsync("ChannelDeleted", new { serverId, channelId });
    }
}
