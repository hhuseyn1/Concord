namespace Concord.Application.Models;

public class TransferStarsRequest
{
    public Guid RecipientUserId { get; set; }

    public int Amount { get; set; }

    /// <summary>Client-generated once per user action/click and reused verbatim on retry, so a
    /// duplicate submission (e.g. a double-click or a retried request) short-circuits instead of
    /// transferring twice.</summary>
    public string IdempotencyKey { get; set; } = null!;
}
