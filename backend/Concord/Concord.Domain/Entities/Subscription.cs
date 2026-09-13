using Concord.Application.Enums;

namespace Concord.Domain.Entities;

public class Subscription : BaseEntity
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string StripeCustomerId { get; set; } = null!;
    public string StripeSubscriptionId { get; set; } = null!;

    public SubscriptionStatus Status { get; set; }
    public DateTime CurrentPeriodEnd { get; set; }
    public bool CancelAtPeriodEnd { get; set; }
}
