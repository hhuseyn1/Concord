using Concord.Application.Enums;
using Concord.Domain.Enums;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Settings;
using Microsoft.EntityFrameworkCore;

namespace Concord.API.Configs;

public static class DatabaseConfig
{
    public static IServiceCollection AddDatabase(this IServiceCollection services, IConfiguration configuration)
    {
        var appSettings = configuration.GetSection(nameof(ApiSettings)).Get<ApiSettings>();

        if (string.IsNullOrWhiteSpace(appSettings?.PostgresConnectionString))
            throw new MissingSettingException(nameof(ApiSettings.PostgresConnectionString));

        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseNpgsql(
                appSettings.PostgresConnectionString,
                builder =>
                {
                    builder.MapEnum<Roles>();
                    builder.MapEnum<FriendRequestStatus>();
                    builder.MapEnum<ChannelType>();
                    builder.MapEnum<PresenceStatus>();
                    builder.MapEnum<NotificationType>();
                    builder.MapEnum<QrLoginStatus>();
                    builder.MapEnum<SubscriptionStatus>();
                }
            )
        );

        return services;
    }
}
