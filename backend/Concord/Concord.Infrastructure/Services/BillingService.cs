using System.Text;
using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Settings;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Stripe;

namespace Concord.Infrastructure.Services;

public class BillingService(
    ApplicationDbContext context,
    StripeClient stripeClient,
    IOptions<StripeSettings> stripeOptions)
{
    private readonly ApplicationDbContext _context = context;
    private readonly StripeClient _stripeClient = stripeClient;
    private readonly StripeSettings _stripeSettings = stripeOptions.Value;

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

    /// <summary>
    /// Creates a Stripe Checkout Session for the user's premium subscription and returns the
    /// hosted checkout URL. Nothing about the session is persisted locally - Stripe remains the
    /// single source of truth, and GetCheckoutSessionStatusAsync queries it live.
    /// </summary>
    public async Task<string> CreateCheckoutSessionAsync(Guid userId)
    {
        var user = await _context.Users.FirstOrDefaultAsync(user => user.Id == userId);

        if (user is null)
            throw new UserNotFoundException(userId);

        // Starting a second Checkout Session for an already-subscribed user would create a second,
        // duplicate Stripe subscription and double-bill them.
        // Note: Select must project to a nullable enum here - FirstOrDefaultAsync() on an empty
        // sequence of the non-nullable enum would return default(SubscriptionStatus), which is
        // Active (the first declared member, value 0), incorrectly blocking every user who has
        // never subscribed at all.
        var latestStatus = await _context.Subscriptions
            .Where(subscription => subscription.UserId == userId)
            .OrderByDescending(subscription => subscription.Created)
            .Select(subscription => (SubscriptionStatus?)subscription.Status)
            .FirstOrDefaultAsync();

        var hasActiveSubscription = latestStatus is SubscriptionStatus.Active or SubscriptionStatus.PastDue;

        if (hasActiveSubscription)
            throw new SubscriptionAlreadyActiveException(userId);

        var customerId = await GetOrCreateStripeCustomerIdAsync(user);

        var options = new Stripe.Checkout.SessionCreateOptions
        {
            Mode = "subscription",
            Customer = customerId,
            ClientReferenceId = userId.ToString(),
            // "hosted" (not "hosted_page") - the installed Stripe.net 50.0.0 pins requests to API
            // version 2025-11-17.clover, which predates the 2026-03-25 ui_mode rename. Using the
            // renamed value against this API version would be rejected by Stripe.
            UiMode = "hosted",
            BillingAddressCollection = "auto",
            PhoneNumberCollection = new Stripe.Checkout.SessionPhoneNumberCollectionOptions
            {
                Enabled = false
            },
            AutomaticTax = new Stripe.Checkout.SessionAutomaticTaxOptions
            {
                Enabled = false
            },
            AllowPromotionCodes = false,
            PaymentMethodCollection = "always",
            SubmitType = "auto",
            SuccessUrl = _stripeSettings.SuccessUrl,
            CancelUrl = _stripeSettings.CancelUrl,
            LineItems =
            [
                new Stripe.Checkout.SessionLineItemOptions
                {
                    Price = _stripeSettings.PremiumPriceId,
                    Quantity = 1
                }
            ]
        };

        var service = new Stripe.Checkout.SessionService(_stripeClient);
        var session = await service.CreateAsync(options);

        return session.Url;
    }

    /// <summary>
    /// Returns the live status of a Checkout Session ("open", "complete", or "expired") for
    /// polling by the frontend. Rejects sessions that were not created for the calling user.
    /// </summary>
    public async Task<string> GetCheckoutSessionStatusAsync(Guid userId, string sessionId)
    {
        var service = new Stripe.Checkout.SessionService(_stripeClient);
        var session = await service.GetAsync(sessionId);

        if (session.ClientReferenceId != userId.ToString())
            throw new AccessDeniedException();

        return session.Status;
    }

    /// <summary>
    /// Returns the calling user's current subscription state, sourced entirely from the local
    /// Subscription table (kept in sync by HandleWebhookAsync) rather than a live Stripe call.
    /// </summary>
    public async Task<SubscriptionResponse> GetSubscriptionAsync(Guid userId)
    {
        var subscription = await _context.Subscriptions
            .Where(subscription => subscription.UserId == userId)
            .OrderByDescending(subscription => subscription.Created)
            .FirstOrDefaultAsync();

        if (subscription is null)
            return new SubscriptionResponse();

        return new SubscriptionResponse
        {
            Status = subscription.Status.ToString(),
            CurrentPeriodEnd = subscription.CurrentPeriodEnd,
            CancelAtPeriodEnd = subscription.CancelAtPeriodEnd
        };
    }

    /// <summary>
    /// Creates a Stripe Customer Portal session for the calling user's Stripe customer and returns
    /// the hosted portal URL, so they can manage or cancel their subscription directly with Stripe.
    /// </summary>
    public async Task<string> CreatePortalSessionAsync(Guid userId)
    {
        var subscription = await _context.Subscriptions
            .Where(subscription => subscription.UserId == userId)
            .OrderByDescending(subscription => subscription.Created)
            .FirstOrDefaultAsync();

        if (subscription is null)
            throw new SubscriptionNotFoundException();

        var service = new Stripe.BillingPortal.SessionService(_stripeClient);
        var session = await service.CreateAsync(new Stripe.BillingPortal.SessionCreateOptions
        {
            Customer = subscription.StripeCustomerId,
            ReturnUrl = _stripeSettings.PortalReturnUrl
        });

        return session.Url;
    }

    /// <summary>
    /// Verifies and processes an incoming Stripe webhook event. Signature verification happens
    /// first via EventUtility.ConstructEvent, which throws Stripe.StripeException on a bad
    /// signature/payload - callers rely on that exception type being distinguishable from any
    /// other failure while processing the event.
    /// </summary>
    public async Task HandleWebhookAsync(byte[] rawBody, string signatureHeader)
    {
        var json = Encoding.UTF8.GetString(rawBody);

        // throwOnApiVersionMismatch defaults to true, which would reject every event whose
        // embedded api_version differs from the version this Stripe.net release expects (we never
        // pin an explicit API version - see StripeConfig - so this SDK's own compiled-in default is
        // effectively "our" version). The account's actual default API version moves independently
        // of when this app upgrades its SDK, so enforcing an exact match here would make webhook
        // processing brittle against something entirely outside this app's control.
        var stripeEvent = EventUtility.ConstructEvent(
            json, signatureHeader, _stripeSettings.WebhookSecret, throwOnApiVersionMismatch: false);

        switch (stripeEvent.Type)
        {
            case EventTypes.CheckoutSessionCompleted:
                await HandleCheckoutSessionCompletedAsync(stripeEvent);
                break;

            case EventTypes.CustomerSubscriptionUpdated:
                await HandleSubscriptionUpdatedAsync(stripeEvent);
                break;

            case EventTypes.CustomerSubscriptionDeleted:
                await HandleSubscriptionDeletedAsync(stripeEvent);
                break;

            case EventTypes.InvoicePaymentFailed:
                await HandleInvoicePaymentFailedAsync(stripeEvent);
                break;

            default:
                // Any other event type is a no-op - still a successful webhook ack.
                break;
        }
    }

    private async Task HandleCheckoutSessionCompletedAsync(Event stripeEvent)
    {
        if (stripeEvent.Data.Object is not Stripe.Checkout.Session session)
            return;

        var userId = Guid.Parse(session.ClientReferenceId);
        var stripeCustomerId = session.CustomerId;
        var stripeSubscriptionId = session.SubscriptionId;

        // The checkout.session.completed event itself doesn't carry status/period-end - retrieve
        // the full Subscription to read them.
        var subscriptionService = new SubscriptionService(_stripeClient);
        var subscription = await subscriptionService.GetAsync(stripeSubscriptionId);

        await UpsertSubscriptionAsync(
            userId,
            stripeCustomerId,
            stripeSubscriptionId,
            MapStatus(subscription.Status),
            GetCurrentPeriodEnd(subscription),
            GetCancelAtPeriodEnd(subscription));
    }

    private async Task HandleSubscriptionUpdatedAsync(Event stripeEvent)
    {
        if (stripeEvent.Data.Object is not Stripe.Subscription subscription)
            return;

        Guid? userId = null;

        var existing = await _context.Subscriptions
            .FirstOrDefaultAsync(row => row.StripeSubscriptionId == subscription.Id);

        // Shouldn't normally happen (checkout.session.completed creates the row first), but handle
        // it defensively by resolving the user from the Stripe Customer's metadata.
        if (existing is null)
        {
            var customerService = new CustomerService(_stripeClient);
            var customer = await customerService.GetAsync(subscription.CustomerId);

            if (customer.Metadata.TryGetValue("ConcordUserId", out var concordUserId) &&
                Guid.TryParse(concordUserId, out var parsedUserId))
            {
                userId = parsedUserId;
            }
        }

        await UpsertSubscriptionAsync(
            userId,
            subscription.CustomerId,
            subscription.Id,
            MapStatus(subscription.Status),
            GetCurrentPeriodEnd(subscription),
            GetCancelAtPeriodEnd(subscription));
    }

    private async Task HandleSubscriptionDeletedAsync(Event stripeEvent)
    {
        if (stripeEvent.Data.Object is not Stripe.Subscription subscription)
            return;

        var existing = await _context.Subscriptions
            .FirstOrDefaultAsync(row => row.StripeSubscriptionId == subscription.Id);

        if (existing is null)
            return;

        existing.Status = SubscriptionStatus.Canceled;
        existing.CurrentPeriodEnd = GetCurrentPeriodEnd(subscription);
        existing.CancelAtPeriodEnd = GetCancelAtPeriodEnd(subscription);

        await _context.SaveChangesAsync();
    }

    private async Task HandleInvoicePaymentFailedAsync(Event stripeEvent)
    {
        if (stripeEvent.Data.Object is not Invoice invoice)
            return;

        // Stripe.net 50.0.0 (API version 2025-11-17.clover) no longer exposes a top-level
        // SubscriptionId on Invoice - the subscription reference now lives nested under
        // Parent.SubscriptionDetails.
        var stripeSubscriptionId = invoice.Parent?.SubscriptionDetails?.SubscriptionId;

        if (string.IsNullOrEmpty(stripeSubscriptionId))
            return;

        var existing = await _context.Subscriptions
            .FirstOrDefaultAsync(row => row.StripeSubscriptionId == stripeSubscriptionId);

        if (existing is null)
            return;

        existing.Status = SubscriptionStatus.PastDue;

        await _context.SaveChangesAsync();
    }

    private async Task UpsertSubscriptionAsync(
        Guid? userId,
        string stripeCustomerId,
        string stripeSubscriptionId,
        SubscriptionStatus status,
        DateTime currentPeriodEnd,
        bool cancelAtPeriodEnd)
    {
        var existing = await _context.Subscriptions
            .FirstOrDefaultAsync(row => row.StripeSubscriptionId == stripeSubscriptionId);

        if (existing is not null)
        {
            existing.StripeCustomerId = stripeCustomerId;
            existing.Status = status;
            existing.CurrentPeriodEnd = currentPeriodEnd;
            existing.CancelAtPeriodEnd = cancelAtPeriodEnd;
        }
        else
        {
            if (userId is null)
                throw new InvalidOperationException(
                    $"Cannot create a Subscription row for Stripe subscription '{stripeSubscriptionId}' without a known userId.");

            _context.Subscriptions.Add(new Concord.Domain.Entities.Subscription
            {
                Id = Guid.NewGuid(),
                UserId = userId.Value,
                StripeCustomerId = stripeCustomerId,
                StripeSubscriptionId = stripeSubscriptionId,
                Status = status,
                CurrentPeriodEnd = currentPeriodEnd,
                CancelAtPeriodEnd = cancelAtPeriodEnd
            });
        }

        await _context.SaveChangesAsync();
    }

    /// <summary>
    /// Maps Stripe's subscription status strings to our 3-value enum. "active"/"trialing" both
    /// grant access, so both map to Active. "past_due"/"unpaid" mean payment is failing but the
    /// subscription isn't dead yet, so both map to PastDue. Everything else ("canceled",
    /// "incomplete_expired", "incomplete", "paused") means the subscription is not usable, so all
    /// collapse to Canceled rather than growing the enum for states we don't otherwise act on.
    /// </summary>
    private static SubscriptionStatus MapStatus(string stripeStatus) => stripeStatus switch
    {
        "active" or "trialing" => SubscriptionStatus.Active,
        "past_due" or "unpaid" => SubscriptionStatus.PastDue,
        _ => SubscriptionStatus.Canceled
    };

    /// <summary>
    /// Stripe removed current_period_end/current_period_start from the top-level Subscription
    /// object in the Basil API version (2025-03-31) - it now only lives per subscription item.
    /// This integration always creates exactly one line item per subscription (the single Premium
    /// price), so Items.Data[0] is always the one we want.
    /// </summary>
    private static DateTime GetCurrentPeriodEnd(Stripe.Subscription subscription) =>
        subscription.Items.Data[0].CurrentPeriodEnd;

    /// <summary>
    /// Whether the subscription is scheduled to lapse at the end of its current period, rather than
    /// renew. Accounts on "classic" billing mode signal this via CancelAtPeriodEnd = true. Accounts
    /// on "flexible" billing mode (Stripe's current default for new accounts) instead leave
    /// CancelAtPeriodEnd false and set CancelAt to the period-end timestamp when a customer
    /// schedules a cancellation through the Customer Portal - see
    /// https://docs.stripe.com/billing/subscriptions/billing-mode/compare#cancellations-in-the-customer-portal.
    /// Checking both keeps this correct regardless of which billing mode the account uses.
    /// </summary>
    private static bool GetCancelAtPeriodEnd(Stripe.Subscription subscription) =>
        subscription.CancelAtPeriodEnd || subscription.CancelAt.HasValue;
}
