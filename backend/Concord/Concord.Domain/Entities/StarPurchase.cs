using Concord.Application.Enums;

namespace Concord.Domain.Entities;

public class StarPurchase : BaseEntity
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string PackageId { get; set; } = null!;

    public int StarsGranted { get; set; }

    public decimal PriceAmount { get; set; }

    public string Currency { get; set; } = null!;

    public StarPurchaseStatus Status { get; set; }

    public string PaymentProvider { get; set; } = "stripe";

    public string? StripeCheckoutSessionId { get; set; }

    public string? StripePaymentIntentId { get; set; }

    public DateTime? CompletedAt { get; set; }
}
