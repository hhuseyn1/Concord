using Concord.Domain.Exceptions;
using Concord.Infrastructure.Settings;
using Stripe;

namespace Concord.API.Configs;

public static class StripeConfig
{
    public static IServiceCollection AddStripe(this IServiceCollection services, IConfiguration configuration)
    {
        var settings = configuration.GetSection(nameof(StripeSettings)).Get<StripeSettings>();

        if (string.IsNullOrWhiteSpace(settings?.SecretKey))
            throw new MissingSettingException(nameof(StripeSettings.SecretKey));

        if (string.IsNullOrWhiteSpace(settings.WebhookSecret))
            throw new MissingSettingException(nameof(StripeSettings.WebhookSecret));

        if (string.IsNullOrWhiteSpace(settings.PremiumPriceId))
            throw new MissingSettingException(nameof(StripeSettings.PremiumPriceId));

        if (string.IsNullOrWhiteSpace(settings.SuccessUrl))
            throw new MissingSettingException(nameof(StripeSettings.SuccessUrl));

        if (string.IsNullOrWhiteSpace(settings.CancelUrl))
            throw new MissingSettingException(nameof(StripeSettings.CancelUrl));

        if (string.IsNullOrWhiteSpace(settings.PortalReturnUrl))
            throw new MissingSettingException(nameof(StripeSettings.PortalReturnUrl));

        services.AddSingleton(new StripeClient(settings.SecretKey));

        return services;
    }
}
