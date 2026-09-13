using Concord.Application.Enums;

namespace Concord.Domain.Entities;

public class Notification : BaseEntity
{
    public Guid Id { get; set; }

    public Guid RecipientUserId { get; set; }

    public NotificationType Type { get; set; }

    public Guid? RelatedUserId { get; set; }

    public bool IsRead { get; set; }

    public DateTime? ReadAt { get; set; }

    /// <summary>Free-text detail for notification types that carry one (currently just
    /// <see cref="Concord.Application.Enums.NotificationType.ReportDismissed"/>) - the admin's
    /// explanation for why a report was dismissed, shown in-app only (never in the push body).</summary>
    public string? Reason { get; set; }

    /// <summary>Navigation context for types that link to a specific message (currently just
    /// Mention, P2.2/P2.7) - nullable and unused by the older notification types, kept on this one
    /// table rather than a parallel type-specific table (see the P2 plan's notification-center
    /// decision: reuse the existing model, don't build a second one).</summary>
    public Guid? ContextServerId { get; set; }
    public Guid? ContextChannelId { get; set; }
    public Guid? ContextConversationId { get; set; }
    public Guid? ContextMessageId { get; set; }
}
