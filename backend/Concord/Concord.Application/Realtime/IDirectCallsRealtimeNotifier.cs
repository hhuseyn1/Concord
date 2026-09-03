using Concord.Application.Models;

namespace Concord.Application.Realtime;

public interface IDirectCallsRealtimeNotifier
{
    Task CallInitiatedAsync(Guid calleeId, CallResponse call);
    Task CallAcceptedAsync(Guid initiatorId, CallResponse call);
    Task CallDeclinedAsync(Guid initiatorId, CallResponse call);
    Task CallEndedAsync(Guid initiatorId, Guid calleeId, CallResponse call);
}
