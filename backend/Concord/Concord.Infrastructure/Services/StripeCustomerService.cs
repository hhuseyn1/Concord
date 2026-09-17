using Concord.Domain.Entities;
using Concord.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;
using Stripe;

namespace Concord.Infrastructure.Services;

public class StripeCustomerService(
    ApplicationDbContext context,
    StripeClient stripeClient)
{
    private readonly ApplicationDbContext _context = context;
    private readonly StripeClient _stripeClient = stripeClient;

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
