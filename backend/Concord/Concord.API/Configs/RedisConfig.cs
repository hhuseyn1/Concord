using Concord.Domain.Exceptions;
using Concord.Infrastructure.Settings;
using StackExchange.Redis;

namespace Concord.API.Configs;

public static class RedisConfig
{
    public static IServiceCollection AddPresenceRedis(this IServiceCollection services, IConfiguration configuration)
    {
        var appSettings = configuration.GetSection(nameof(ApiSettings)).Get<ApiSettings>();

        if (string.IsNullOrWhiteSpace(appSettings?.RedisConnectionString))
            throw new MissingSettingException(nameof(ApiSettings.RedisConnectionString));

        services.AddSingleton<IConnectionMultiplexer>(_ => ConnectionMultiplexer.Connect(appSettings.RedisConnectionString));
        services.AddSingleton(sp => sp.GetRequiredService<IConnectionMultiplexer>().GetDatabase());

        return services;
    }
}
