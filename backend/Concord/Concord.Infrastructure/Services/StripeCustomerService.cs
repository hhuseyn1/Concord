using Concord.Domain.Entities;
using Concord.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;
using Stripe;

namespace Concord.Infrastructure.Services;

/// <summary>
/// Resolves/creates the Stripe Customer for a user. Extracted out of <see cref="BillingService"/> so
/// both it and the Stars purchase flow (<see cref="StarsService"/>) can depend on this without
/// <see cref="StarsService"/> depending back on <see cref="BillingService"/> - see StarsService's
/// remarks on why that circular dependency must be avoided (BillingService's webhook dispatch calls
/// into StarsService for `checkout.session.completed` events in "payment" mode).
/// </summary>
public class StripeCustomerService(
    ApplicationDbContext context,
    StripeClient stripeClient)
{
    private readonly ApplicationDbContext _context = context;
    private readonly StripeClient _stripeClient = stripeClient;

    /// <summary>
    /// Returns the Stripe Customer id for the given user, reusing the one from their most recent
    /// local Subscription row (no Stripe API call needed) if one exists. Otherwise creates a new
    /// Stripe Customer, tagged with metadata for reconciliation, and returns its id.
    /// </summary>
    public async Task<string> GetOrCreateStripeCustomerIdAsync(User user)
    {
        var existingSubscription = await _context.Subscriptions
            .Where(subscription => subscription.UserId == user.Id)
            .OrderByDescending(subscription => subscription.Created)
            .FirstOrDefaultAsync();

        if (existingSubscription is not null)
            return existingSubscription.StripeCustomerId;

        var options = new CustomerCreateOptions
        {
            Email = user.Email,
            Metadata = new Dictionary<string, string>
            {
                ["ConcordUserId"] = user.Id.ToString()
            }
        };

        var requestOptions = new RequestOptions
        {
            IdempotencyKey = $"customer-create-{user.Id}"
        };

        var service = new CustomerService(_stripeClient);
        var customer = await service.CreateAsync(options, requestOptions);

        return customer.Id;
    }
}
