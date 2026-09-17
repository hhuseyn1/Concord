namespace Concord.Application.Models;

public class TransferStarsRequest
{
    public Guid RecipientUserId { get; set; }

    public int Amount { get; set; }

    public string IdempotencyKey { get; set; } = null!;
}
