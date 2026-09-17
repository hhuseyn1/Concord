using Concord.Domain.Exceptions;
using Concord.Infrastructure.Settings;
using Livekit.Server.Sdk.Dotnet;

namespace Concord.API.Configs;

public static class LiveKitConfig
{
    public static IServiceCollection AddLiveKit(this IServiceCollection services, IConfiguration configuration)
    {
        var settings = configuration.GetSection(nameof(LiveKitSettings)).Get<LiveKitSettings>();

        if (string.IsNullOrWhiteSpace(settings?.Url))
            throw new MissingSettingException(nameof(LiveKitSettings.Url));

        if (string.IsNullOrWhiteSpace(settings.ApiKey))
            throw new MissingSettingException(nameof(LiveKitSettings.ApiKey));

        if (string.IsNullOrWhiteSpace(settings.ApiSecret))
            throw new MissingSettingException(nameof(LiveKitSettings.ApiSecret));

        var managementUrl = ToHttpScheme(settings.Url);

        services.AddSingleton(new RoomServiceClient(managementUrl, settings.ApiKey, settings.ApiSecret));

        return services;
    }

    private static string ToHttpScheme(string url)
    {
        if (url.StartsWith("wss://", StringComparison.OrdinalIgnoreCase))
            return "https://" + url["wss://".Length..];

        if (url.StartsWith("ws://", StringComparison.OrdinalIgnoreCase))
            return "http://" + url["ws://".Length..];

        return url;
    }
}
