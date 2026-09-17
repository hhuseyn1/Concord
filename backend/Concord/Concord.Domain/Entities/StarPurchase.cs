using Concord.Application.Enums;

namespace Concord.Domain.Entities;

/// <summary>
/// One row per real-money Stars order, created Pending before the Stripe Checkout Session exists
/// and completed only by a verified <c>checkout.session.completed</c> webhook event - see
/// <c>StarsService.CreateCheckoutSessionAsync</c>/<c>CompleteStarsPurchaseAsync</c>.
/// </summary>
public class StarPurchase : BaseEntity
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    /// <summary>Matches a <c>StarsConstants.Packages</c> entry's Id at the time of purchase.</summary>
    public string PackageId { get; set; } = null!;

    /// <summary>Snapshot of the package's star count at purchase time - the catalog could change later.</summary>
    public int StarsGranted { get; set; }

    public decimal PriceAmount { get; set; }

    public string Currency { get; set; } = null!;

    public StarPurchaseStatus Status { get; set; }

    public string PaymentProvider { get; set; } = "stripe";

    public string? StripeCheckoutSessionId { get; set; }

    public string? StripePaymentIntentId { get; set; }

    public DateTime? CompletedAt { get; set; }
}
