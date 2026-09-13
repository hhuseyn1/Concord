using Concord.Application.Models;
using Concord.Domain.Entities;

namespace Concord.Infrastructure.Extensions;

public static class SubscriptionExtensions
{
    /// <summary>Admin-only row shape (P4) - see <see cref="AdminSubscriptionSummary"/> for why this
    /// intentionally includes every subscription row rather than one per user.</summary>
    public static AdminSubscriptionSummary MapToAdminSummary(this Subscription subscription, User user) => new()
    {
        Id = subscription.Id,
        UserId = subscription.UserId,
        Username = user.Username ?? string.Empty,
        Email = user.Email ?? string.Empty,
        Status = subscription.Status.ToString(),
        CurrentPeriodEnd = subscription.CurrentPeriodEnd,
        CancelAtPeriodEnd = subscription.CancelAtPeriodEnd,
        StripeCustomerId = subscription.StripeCustomerId,
        StripeSubscriptionId = subscription.StripeSubscriptionId,
        Created = subscription.Created
    };
}
