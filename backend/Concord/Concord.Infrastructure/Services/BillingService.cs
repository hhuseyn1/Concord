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
    IOptions<StripeSettings> stripeOptions,
    StripeCustomerService stripeCustomerService,
    StarsService starsService)
{
    private readonly ApplicationDbContext _context = context;
    private readonly StripeClient _stripeClient = stripeClient;
    private readonly StripeSettings _stripeSettings = stripeOptions.Value;
    private readonly StripeCustomerService _stripeCustomerService = stripeCustomerService;
    private readonly StarsService _starsService = starsService;

    public Task<string> GetOrCreateStripeCustomerIdAsync(User user) =>
        _stripeCustomerService.GetOrCreateStripeCustomerIdAsync(user);

    public async Task<string> CreateCheckoutSessionAsync(Guid userId)
    {
        var user = await _context.Users.FirstOrDefaultAsync(user => user.Id == userId);

        if (user is null)
            throw new UserNotFoundException(userId);

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

    public async Task<string> GetCheckoutSessionStatusAsync(Guid userId, string sessionId)
    {
        var service = new Stripe.Checkout.SessionService(_stripeClient);
        var session = await service.GetAsync(sessionId);

        if (session.ClientReferenceId != userId.ToString())
            throw new AccessDeniedException();

        return session.Status;
    }

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

    public async Task HandleWebhookAsync(byte[] rawBody, string signatureHeader)
    {
        var json = Encoding.UTF8.GetString(rawBody);

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
                break;
        }
    }

    private async Task HandleCheckoutSessionCompletedAsync(Event stripeEvent)
    {
        if (stripeEvent.Data.Object is not Stripe.Checkout.Session session)
            return;

        if (session.Mode == "payment" || session.Metadata?.GetValueOrDefault("Type") == "StarsPurchase")
        {
            await _starsService.CompleteStarsPurchaseAsync(session);
            return;
        }

        var userId = Guid.Parse(session.ClientReferenceId);
        var stripeCustomerId = session.CustomerId;
        var stripeSubscriptionId = session.SubscriptionId;

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

    private static SubscriptionStatus MapStatus(string stripeStatus) => stripeStatus switch
    {
        "active" or "trialing" => SubscriptionStatus.Active,
        "past_due" or "unpaid" => SubscriptionStatus.PastDue,
        _ => SubscriptionStatus.Canceled
    };

    private static DateTime GetCurrentPeriodEnd(Stripe.Subscription subscription) =>
        subscription.Items.Data[0].CurrentPeriodEnd;

    private static bool GetCancelAtPeriodEnd(Stripe.Subscription subscription) =>
        subscription.CancelAtPeriodEnd || subscription.CancelAt.HasValue;
}
