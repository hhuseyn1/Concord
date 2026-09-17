namespace Concord.Domain.Entities;

public class Message : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ChannelId { get; set; }
    public Guid SenderId { get; set; }

    public string? Content { get; set; }

    public DateTime? EditedAtUtc { get; set; }

    public string? AttachmentUrl { get; set; }

    public Guid? ReplyToMessageId { get; set; }

    public DateTime? PinnedAt { get; set; }
    public Guid? PinnedByUserId { get; set; }

    public Guid? ForwardedFromSenderId { get; set; }
    public DateTime? ForwardedFromCreatedAt { get; set; }

    public bool MentionsEveryone { get; set; }
}
