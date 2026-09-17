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

    public string? Reason { get; set; }

    public Guid? ContextServerId { get; set; }
    public Guid? ContextChannelId { get; set; }
    public Guid? ContextConversationId { get; set; }
    public Guid? ContextMessageId { get; set; }
}
