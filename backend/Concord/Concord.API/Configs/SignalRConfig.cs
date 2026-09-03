using Concord.Domain.Exceptions;
using Concord.Infrastructure.Settings;
using Microsoft.AspNetCore.SignalR;

namespace Concord.API.Configs;

public static class SignalRConfig
{
    public static IServiceCollection AddSignalRWithRedisBackplane(this IServiceCollection services, IConfiguration configuration)
    {
        var appSettings = configuration.GetSection(nameof(ApiSettings)).Get<ApiSettings>();

        if (string.IsNullOrWhiteSpace(appSettings?.RedisConnectionString))
            throw new MissingSettingException(nameof(ApiSettings.RedisConnectionString));

        services.AddSignalR().AddStackExchangeRedis(appSettings.RedisConnectionString);
        services.AddSingleton<IUserIdProvider, JwtUserIdProvider>();

        return services;
    }
}
