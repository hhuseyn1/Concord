using Concord.API.Hubs;
using Concord.Application.Models;
using Concord.Application.Realtime;
using Microsoft.AspNetCore.SignalR;

namespace Concord.API.Realtime;

public class SignalRDirectCallsNotifier(IHubContext<DirectMessagesHub> hubContext) : IDirectCallsRealtimeNotifier
{
    private readonly IHubContext<DirectMessagesHub> _hubContext = hubContext;

    public async Task CallInitiatedAsync(Guid calleeId, CallResponse call)
    {
        await _hubContext.Clients.User(calleeId.ToString()).SendAsync("DirectCallInitiated", call);
    }

    public async Task CallAcceptedAsync(Guid initiatorId, CallResponse call)
    {
        await _hubContext.Clients.User(initiatorId.ToString()).SendAsync("DirectCallAccepted", call);
    }

    public async Task CallDeclinedAsync(Guid initiatorId, CallResponse call)
    {
        await _hubContext.Clients.User(initiatorId.ToString()).SendAsync("DirectCallDeclined", call);
    }

    public async Task CallEndedAsync(Guid initiatorId, Guid calleeId, CallResponse call)
    {
        await _hubContext.Clients.Users([initiatorId.ToString(), calleeId.ToString()]).SendAsync("DirectCallEnded", call);
    }
}
