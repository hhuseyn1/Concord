using Concord.Application.Auditing;
using Concord.Application.Email;
using Concord.Application.Push;
using Concord.Infrastructure.Services;

namespace Concord.API.Configs;

public static class ServicesConfig
{
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services)
    {
        services.AddScoped<IEmailSender, SmtpEmailSender>();
        services.AddScoped<TwoFactorService>();
        services.AddScoped<AuthenticationService>();
        services.AddScoped<QrLoginService>();
        services.AddScoped<AdminService>();
        services.AddScoped<UsersService>();
        services.AddScoped<FriendsService>();
        services.AddScoped<PermissionService>();
        services.AddScoped<RolesService>();
        services.AddScoped<ModerationService>();
        services.AddScoped<ServersService>();
        services.AddScoped<ChannelsService>();
        services.AddScoped<MessagesService>();
        services.AddScoped<DirectMessagesService>();
        services.AddScoped<PresenceService>();
        services.AddScoped<FilesService>();
        services.AddScoped<NotificationsService>();
        services.AddScoped<VoiceService>();
        services.AddScoped<SessionsService>();
        services.AddScoped<DirectCallsService>();
        services.AddScoped<ForwardingService>();
        services.AddScoped<GlobalSearchService>();
        services.AddScoped<ReportsService>();
        services.AddScoped<IAuditLogService, AuditLogService>();
        services.AddScoped<PushTokensService>();
        services.AddScoped<IPushNotificationSender, NoOpPushNotificationSender>();

        return services;
    }
}
