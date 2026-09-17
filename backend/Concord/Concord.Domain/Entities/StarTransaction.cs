using Concord.Application.Enums;

namespace Concord.Domain.Entities;

public class StarTransaction : BaseEntity
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public StarTransactionType Type { get; set; }

    public int Amount { get; set; }

    public int BalanceAfter { get; set; }

    public Guid? CounterpartyUserId { get; set; }

    public Guid? RelatedPurchaseId { get; set; }

    public string? IdempotencyKey { get; set; }
}
