using Concord.Domain.Entities;
using Concord.Domain.Enums;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Services;
using Concord.Infrastructure.Settings;
using Microsoft.Extensions.Options;
using Stripe;

namespace Concord.Tests;

/// <summary>
/// Wires up a real <see cref="StarsService"/> (and the small slice of <see cref="FriendsService"/>
/// it depends on) against a given <see cref="ApplicationDbContext"/>, without mocking either - only
/// the Stripe-facing collaborators are given inert/unused instances, since none of the money-safety
/// tests exercise the Stripe checkout paths.
/// </summary>
internal static class StarsServiceTestFactory
{
    public static StarsService Create(ApplicationDbContext context)
    {
        // Never used for real network calls in these tests (no test exercises checkout-session
        // creation) - a syntactically-valid-looking fake key is enough to construct the client.
        var stripeClient = new StripeClient("sk_test_fake_key_for_unit_tests");

        var stripeSettings = Options.Create(new StripeSettings
        {
            SecretKey = "sk_test_fake_key_for_unit_tests",
            WebhookSecret = "whsec_fake",
            PremiumPriceId = "price_fake",
            SuccessUrl = "https://example.com/success",
            CancelUrl = "https://example.com/cancel",
            PortalReturnUrl = "https://example.com/portal",
            StarsSuccessUrl = "https://example.com/stars/success",
            StarsCancelUrl = "https://example.com/stars/cancel"
        });

        var stripeCustomerService = new StripeCustomerService(context, stripeClient);

        // FriendsService's other dependencies (NotificationsService, ServersService, the realtime
        // notifier) are only exercised by friend-request/blocking flows, never by AreFriendsAsync -
        // the only FriendsService method StarsService calls. Passing null! for them keeps this
        // factory from having to stand up the rest of the notification stack for tests that never
        // touch it.
        var friendsService = new FriendsService(context, null!, null!, null!);

        return new StarsService(context, stripeClient, stripeSettings, stripeCustomerService, friendsService);
    }

    public static User CreateUser(string username)
    {
        return new User($"{username}@example.com", "hash", null, "en-EN", Roles.User, "Test", "User")
        {
            Username = username
        };
    }

    public static async Task MakeFriendsAsync(ApplicationDbContext context, Guid userIdA, Guid userIdB)
    {
        context.FriendRequests.Add(new FriendRequest
        {
            RequesterId = userIdA,
            AddresseeId = userIdB,
            Status = Concord.Application.Enums.FriendRequestStatus.Accepted
        });

        await context.SaveChangesAsync();
    }
}
