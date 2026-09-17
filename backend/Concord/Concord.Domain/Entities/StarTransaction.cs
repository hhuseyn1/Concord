using Concord.Application.Enums;

namespace Concord.Domain.Entities;

/// <summary>
/// Append-only audit ledger for every Stars balance change. Every code path that mutates
/// <see cref="User.StarsBalance"/> must insert exactly one of these alongside the balance change -
/// see <c>StarsService</c>.
/// </summary>
public class StarTransaction : BaseEntity
{
    public Guid Id { get; set; }

    /// <summary>The ledger owner - whose balance this row's <see cref="Amount"/> was applied to.</summary>
    public Guid UserId { get; set; }

    public StarTransactionType Type { get; set; }

    /// <summary>Signed: positive for credits, negative for debits.</summary>
    public int Amount { get; set; }

    /// <summary>Snapshot of <see cref="User.StarsBalance"/> immediately after this transaction applied.</summary>
    public int BalanceAfter { get; set; }

    /// <summary>The other party for TransferSent/TransferReceived rows; null otherwise.</summary>
    public Guid? CounterpartyUserId { get; set; }

    /// <summary>The originating <see cref="StarPurchase"/> for PackagePurchase rows; null otherwise.</summary>
    public Guid? RelatedPurchaseId { get; set; }

    /// <summary>
    /// Client-supplied idempotency token for retry-safe money-moving requests (transfer, premium
    /// trial activation). Nullable - chat rewards and webhook-driven package purchases don't carry
    /// one. Unique per (UserId, IdempotencyKey) where not null - see
    /// ApplicationDbContext.ConfigureStarTransaction.
    /// </summary>
    public string? IdempotencyKey { get; set; }
}
