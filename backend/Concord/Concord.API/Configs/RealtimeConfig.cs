using Concord.API.Realtime;
using Concord.Application.Realtime;

namespace Concord.API.Configs;

public static class RealtimeConfig
{
    public static IServiceCollection AddRealtimeNotifiers(this IServiceCollection services)
    {
        services.AddScoped<IDirectMessagesRealtimeNotifier, SignalRDirectMessagesNotifier>();
        services.AddScoped<IMessagesRealtimeNotifier, SignalRMessagesNotifier>();
        services.AddScoped<IServersRealtimeNotifier, SignalRServersNotifier>();
        services.AddScoped<IDirectCallsRealtimeNotifier, SignalRDirectCallsNotifier>();
        services.AddScoped<IVoiceRealtimeNotifier, SignalRVoiceNotifier>();
        services.AddScoped<INotificationsRealtimeNotifier, SignalRNotificationsNotifier>();

        return services;
    }
}
