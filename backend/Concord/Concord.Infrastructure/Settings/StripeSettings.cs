namespace Concord.Infrastructure.Settings;

public class StripeSettings
{
    public string SecretKey { get; set; } = null!;
    public string WebhookSecret { get; set; } = null!;
    public string PremiumPriceId { get; set; } = null!;
    public string SuccessUrl { get; set; } = null!;
    public string CancelUrl { get; set; } = null!;
    public string PortalReturnUrl { get; set; } = null!;
}
