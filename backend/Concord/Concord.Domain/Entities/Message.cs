namespace Concord.Domain.Entities;

public class Message : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ChannelId { get; set; }
    public Guid SenderId { get; set; }

    public string? Content { get; set; }

    public DateTime? EditedAtUtc { get; set; }

    public string? AttachmentUrl { get; set; }

    /// <summary>The message this one replies to (M-02), same channel, or <c>null</c> for a plain
    /// message. Set to <c>null</c> automatically if the target is later deleted (see
    /// <c>ConfigureMessage</c>'s <c>DeleteBehavior.SetNull</c>) rather than blocking or cascading that
    /// delete.</summary>
    public Guid? ReplyToMessageId { get; set; }

    public DateTime? PinnedAt { get; set; }
    public Guid? PinnedByUserId { get; set; }

    /// <summary>Set once, at forward time (P2.5) - a copy of the source message's sender/timestamp,
    /// never a live pointer, so deleting the original later doesn't affect a forwarded copy.</summary>
    public Guid? ForwardedFromSenderId { get; set; }
    public DateTime? ForwardedFromCreatedAt { get; set; }

    /// <summary>Set when the sender typed the literal <c>@everyone</c> token and held
    /// <see cref="Concord.Application.Enums.ServerPermission.MentionEveryone"/> at send time (P3).
    /// Deliberately not backed by a <see cref="MessageMention"/> row per recipient - that table is
    /// per-specific-user, and one row per server member for every <c>@everyone</c> would be wasteful
    /// on a large server. Clients infer "you were mentioned" from this flag plus their own server
    /// membership instead.</summary>
    public bool MentionsEveryone { get; set; }
}
