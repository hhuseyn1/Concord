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

public class StarsService(
    ApplicationDbContext context,
    StripeClient stripeClient,
    IOptions<StripeSettings> stripeOptions,
    StripeCustomerService stripeCustomerService,
    FriendsService friendsService)
{
    private readonly ApplicationDbContext _context = context;
    private readonly StripeClient _stripeClient = stripeClient;
    private readonly StripeSettings _stripeSettings = stripeOptions.Value;
    private readonly StripeCustomerService _stripeCustomerService = stripeCustomerService;
    private readonly FriendsService _friendsService = friendsService;

    public static StarsConfigResponse GetConfig()
    {
        return new StarsConfigResponse
        {
            ChatRewardAmount = StarsConstants.ChatRewardAmount,
            ChatRewardCooldownSeconds = StarsConstants.ChatRewardCooldownSeconds,
            ChatRewardDailyCap = StarsConstants.ChatRewardDailyCap,
            PremiumTrialCostStars = StarsConstants.PremiumTrialCostStars,
            PremiumTrialDurationDays = StarsConstants.PremiumTrialDurationDays,
            Packages = StarsConstants.Packages
                .Select(package => new StarPackageResponse
                {
                    Id = package.Id,
                    Stars = package.Stars,
                    PriceAmount = package.PriceAmount,
                    Currency = package.Currency
                })
                .ToList()
        };
    }

    public async Task<StarWalletResponse> GetWalletAsync(Guid userId)
    {
        var user = await _context.Users.FirstOrDefaultAsync(user => user.Id == userId);

        if (user is null)
            throw new UserNotFoundException(userId);

        var trialActive = IsTrialActive(user);
        var hasActiveSubscription = await HasActiveSubscriptionAsync(userId);

        return new StarWalletResponse
        {
            Balance = user.StarsBalance,
            PremiumTrialActive = trialActive,
            PremiumTrialExpiresAt = user.PremiumTrialExpiresAt,
            HasActivePremium = trialActive || hasActiveSubscription
        };
    }

    public async Task<PagedResult<StarTransactionResponse>> GetTransactionsAsync(Guid userId, int page, int pageSize)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        var query = _context.StarTransactions.Where(transaction => transaction.UserId == userId);

        var totalCount = await query.CountAsync();

        var transactions = await query
            .OrderByDescending(transaction => transaction.Created)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var counterpartyIds = transactions
            .Where(transaction => transaction.CounterpartyUserId.HasValue)
            .Select(transaction => transaction.CounterpartyUserId!.Value)
            .Distinct()
            .ToList();

        var usernamesById = await _context.Users
            .Where(user => counterpartyIds.Contains(user.Id))
            .ToDictionaryAsync(user => user.Id, user => user.Username);

        return new PagedResult<StarTransactionResponse>
        {
            Items = transactions
                .Select(transaction => new StarTransactionResponse
                {
                    Id = transaction.Id,
                    Type = transaction.Type,
                    Amount = transaction.Amount,
                    BalanceAfter = transaction.BalanceAfter,
                    CounterpartyUsername = transaction.CounterpartyUserId.HasValue
                        ? usernamesById.GetValueOrDefault(transaction.CounterpartyUserId.Value)
                        : null,
                    Created = transaction.Created
                })
                .ToList(),
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    public async Task<TransferStarsResponse> TransferAsync(Guid senderId, TransferStarsRequest request)
    {
        if (request.Amount <= 0)
            throw new ParameterValidationException(nameof(request.Amount), "Amount must be positive.");

        if (request.RecipientUserId == senderId)
            throw new CannotTargetSelfException();

        if (string.IsNullOrWhiteSpace(request.IdempotencyKey))
            throw new ParameterValidationException(nameof(request.IdempotencyKey));

        var existing = await _context.StarTransactions.FirstOrDefaultAsync(transaction =>
            transaction.UserId == senderId &&
            transaction.Type == StarTransactionType.TransferSent &&
            transaction.IdempotencyKey == request.IdempotencyKey);

        if (existing is not null)
            return new TransferStarsResponse { Balance = existing.BalanceAfter };

        var recipient = await _context.Users.FirstOrDefaultAsync(user => user.Id == request.RecipientUserId);

        if (recipient is null || recipient.Disabled.HasValue)
            throw new UserNotFoundException(request.RecipientUserId);

        var areFriends = await _friendsService.AreFriendsAsync(senderId, request.RecipientUserId);

        if (!areFriends)
            throw new NotFriendsException();

        await using var transaction = await _context.Database.BeginTransactionAsync();

        var debitedRows = await _context.Users
            .Where(user => user.Id == senderId && user.StarsBalance >= request.Amount)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(user => user.StarsBalance, user => user.StarsBalance - request.Amount));

        if (debitedRows == 0)
            throw new InsufficientStarsBalanceException();

        var senderBalance = await _context.Users
            .Where(user => user.Id == senderId)
            .Select(user => user.StarsBalance)
            .FirstAsync();

        await _context.Users
            .Where(user => user.Id == request.RecipientUserId)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(user => user.StarsBalance, user => user.StarsBalance + request.Amount));

        var recipientBalance = await _context.Users
            .Where(user => user.Id == request.RecipientUserId)
            .Select(user => user.StarsBalance)
            .FirstAsync();

        _context.StarTransactions.Add(new StarTransaction
        {
            UserId = senderId,
            Type = StarTransactionType.TransferSent,
            Amount = -request.Amount,
            BalanceAfter = senderBalance,
            CounterpartyUserId = request.RecipientUserId,
            IdempotencyKey = request.IdempotencyKey
        });

        _context.StarTransactions.Add(new StarTransaction
        {
            UserId = request.RecipientUserId,
            Type = StarTransactionType.TransferReceived,
            Amount = request.Amount,
            BalanceAfter = recipientBalance,
            CounterpartyUserId = senderId
        });

        await _context.SaveChangesAsync();
        await transaction.CommitAsync();

        return new TransferStarsResponse { Balance = senderBalance };
    }

    public async Task<ActivatePremiumTrialResponse> ActivatePremiumTrialAsync(Guid userId, ActivatePremiumTrialRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.IdempotencyKey))
            throw new ParameterValidationException(nameof(request.IdempotencyKey));

        var existing = await _context.StarTransactions.FirstOrDefaultAsync(transaction =>
            transaction.UserId == userId &&
            transaction.Type == StarTransactionType.PremiumTrialPurchase &&
            transaction.IdempotencyKey == request.IdempotencyKey);

        if (existing is not null)
        {
            var existingUser = await _context.Users.FirstOrDefaultAsync(user => user.Id == userId);

            if (existingUser is null)
                throw new UserNotFoundException(userId);

            return new ActivatePremiumTrialResponse
            {
                Balance = existing.BalanceAfter,
                PremiumTrialExpiresAt = existingUser.PremiumTrialExpiresAt ?? existingUser.Created
            };
        }

        var user = await _context.Users.FirstOrDefaultAsync(user => user.Id == userId);

        if (user is null)
            throw new UserNotFoundException(userId);

        if (IsTrialActive(user))
            throw new PremiumTrialAlreadyActiveException();

        if (await HasActiveSubscriptionAsync(userId))
            throw new PremiumTrialAlreadyActiveException();

        await using var transaction = await _context.Database.BeginTransactionAsync();

        var debitedRows = await _context.Users
            .Where(u => u.Id == userId && u.StarsBalance >= StarsConstants.PremiumTrialCostStars)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(u => u.StarsBalance, u => u.StarsBalance - StarsConstants.PremiumTrialCostStars));

        if (debitedRows == 0)
            throw new InsufficientStarsBalanceException();

        var expiresAt = DateTime.UtcNow.AddDays(StarsConstants.PremiumTrialDurationDays);

        await _context.Users
            .Where(u => u.Id == userId)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(u => u.PremiumTrialExpiresAt, expiresAt));

        var balanceAfter = await _context.Users
            .Where(u => u.Id == userId)
            .Select(u => u.StarsBalance)
            .FirstAsync();

        _context.StarTransactions.Add(new StarTransaction
        {
            UserId = userId,
            Type = StarTransactionType.PremiumTrialPurchase,
            Amount = -StarsConstants.PremiumTrialCostStars,
            BalanceAfter = balanceAfter,
            IdempotencyKey = request.IdempotencyKey
        });

        await _context.SaveChangesAsync();
        await transaction.CommitAsync();

        return new ActivatePremiumTrialResponse
        {
            Balance = balanceAfter,
            PremiumTrialExpiresAt = expiresAt
        };
    }

    public async Task TryGrantChatRewardAsync(User sender, string? content)
    {
        var trimmed = content?.Trim() ?? string.Empty;

        if (trimmed.Length < StarsConstants.ChatRewardMinMessageLength)
            return;

        var now = DateTime.UtcNow;

        if (sender.LastStarRewardAt.HasValue &&
            (now - sender.LastStarRewardAt.Value).TotalSeconds < StarsConstants.ChatRewardCooldownSeconds)
            return;

        var today = DateOnly.FromDateTime(now.AddHours(GlobalConstants.TimeZoneOffsetHours));

        if (sender.StarsEarnedTodayDate != today)
        {
            sender.StarsEarnedToday = 0;
            sender.StarsEarnedTodayDate = today;
        }

        if (sender.StarsEarnedToday + StarsConstants.ChatRewardAmount > StarsConstants.ChatRewardDailyCap)
            return;

        sender.StarsBalance += StarsConstants.ChatRewardAmount;
        sender.LastStarRewardAt = now;
        sender.StarsEarnedToday += StarsConstants.ChatRewardAmount;

        _context.StarTransactions.Add(new StarTransaction
        {
            UserId = sender.Id,
            Type = StarTransactionType.ChatReward,
            Amount = StarsConstants.ChatRewardAmount,
            BalanceAfter = sender.StarsBalance
        });

        await _context.SaveChangesAsync();
    }

    public async Task<CreateStarsCheckoutSessionResponse> CreateCheckoutSessionAsync(Guid userId, string packageId)
    {
        var package = StarsConstants.Packages.FirstOrDefault(package => package.Id == packageId);

        if (package is null)
            throw new StarPackageNotFoundException();

        var user = await _context.Users.FirstOrDefaultAsync(user => user.Id == userId);

        if (user is null)
            throw new UserNotFoundException(userId);

        var customerId = await _stripeCustomerService.GetOrCreateStripeCustomerIdAsync(user);

        var purchase = new StarPurchase
        {
            UserId = userId,
            PackageId = package.Id,
            StarsGranted = package.Stars,
            PriceAmount = package.PriceAmount,
            Currency = package.Currency,
            Status = StarPurchaseStatus.Pending,
            PaymentProvider = "stripe"
        };

        _context.StarPurchases.Add(purchase);
        await _context.SaveChangesAsync();

        var options = new Stripe.Checkout.SessionCreateOptions
        {
            Mode = "payment",
            Customer = customerId,
            ClientReferenceId = purchase.Id.ToString(),
            UiMode = "hosted",
            BillingAddressCollection = "auto",
            AutomaticTax = new Stripe.Checkout.SessionAutomaticTaxOptions
            {
                Enabled = false
            },
            AllowPromotionCodes = false,
            SuccessUrl = AppendPurchaseIdQueryParam(_stripeSettings.StarsSuccessUrl, purchase.Id),
            CancelUrl = _stripeSettings.StarsCancelUrl,
            Metadata = new Dictionary<string, string>
            {
                ["Type"] = "StarsPurchase"
            },
            LineItems =
            [
                new Stripe.Checkout.SessionLineItemOptions
                {
                    Quantity = 1,
                    PriceData = new Stripe.Checkout.SessionLineItemPriceDataOptions
                    {
                        Currency = package.Currency,
                        UnitAmountDecimal = package.PriceAmount * 100,
                        ProductData = new Stripe.Checkout.SessionLineItemPriceDataProductDataOptions
                        {
                            Name = $"{package.Stars} Concord Stars"
                        }
                    }
                }
            ]
        };

        var service = new Stripe.Checkout.SessionService(_stripeClient);
        var session = await service.CreateAsync(options);

        purchase.StripeCheckoutSessionId = session.Id;
        await _context.SaveChangesAsync();

        return new CreateStarsCheckoutSessionResponse { Url = session.Url, PurchaseId = purchase.Id };
    }

    private static string AppendPurchaseIdQueryParam(string successUrl, Guid purchaseId)
    {
        if (string.IsNullOrWhiteSpace(successUrl))
            return successUrl;

        var separator = successUrl.Contains('?') ? '&' : '?';

        return $"{successUrl}{separator}purchase_id={purchaseId}";
    }

    public async Task<StarPurchaseStatus> GetPurchaseStatusAsync(Guid userId, Guid purchaseId)
    {
        var purchase = await _context.StarPurchases.FirstOrDefaultAsync(purchase => purchase.Id == purchaseId);

        if (purchase is null)
            throw new StarPurchaseNotFoundException();

        if (purchase.UserId != userId)
            throw new AccessDeniedException();

        return purchase.Status;
    }

    public async Task CompleteStarsPurchaseAsync(Stripe.Checkout.Session session)
    {
        if (string.IsNullOrEmpty(session.ClientReferenceId) || !Guid.TryParse(session.ClientReferenceId, out var purchaseId))
            return;

        var purchase = await _context.StarPurchases.FirstOrDefaultAsync(purchase => purchase.Id == purchaseId);

        if (purchase is null)
            return;

        await using var transaction = await _context.Database.BeginTransactionAsync();

        var completedRows = await _context.StarPurchases
            .Where(p => p.Id == purchaseId && p.Status == StarPurchaseStatus.Pending)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(p => p.Status, StarPurchaseStatus.Completed)
                .SetProperty(p => p.CompletedAt, DateTime.UtcNow)
                .SetProperty(p => p.StripePaymentIntentId, session.PaymentIntentId));

        if (completedRows == 0)
        {
            return;
        }

        await _context.Users
            .Where(user => user.Id == purchase.UserId)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(user => user.StarsBalance, user => user.StarsBalance + purchase.StarsGranted));

        var balanceAfter = await _context.Users
            .Where(user => user.Id == purchase.UserId)
            .Select(user => user.StarsBalance)
            .FirstAsync();

        _context.StarTransactions.Add(new StarTransaction
        {
            UserId = purchase.UserId,
            Type = StarTransactionType.PackagePurchase,
            Amount = purchase.StarsGranted,
            BalanceAfter = balanceAfter,
            RelatedPurchaseId = purchase.Id
        });

        await _context.SaveChangesAsync();
        await transaction.CommitAsync();
    }

    private static bool IsTrialActive(User user) =>
        user.PremiumTrialExpiresAt.HasValue && user.PremiumTrialExpiresAt.Value > DateTime.UtcNow;

    private async Task<bool> HasActiveSubscriptionAsync(Guid userId)
    {
        var latestStatus = await _context.Subscriptions
            .Where(subscription => subscription.UserId == userId)
            .OrderByDescending(subscription => subscription.Created)
            .Select(subscription => (SubscriptionStatus?)subscription.Status)
            .FirstOrDefaultAsync();

        return latestStatus is SubscriptionStatus.Active or SubscriptionStatus.PastDue;
    }
}
