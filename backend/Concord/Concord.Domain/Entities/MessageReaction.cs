namespace Concord.Domain.Entities;

/// <summary>One user's reaction (M-01) to one message with one emoji. Toggled, not edited - reacting
/// again with the same emoji removes this row (see <c>MessagesService.ToggleReactionAsync</c>);
/// reacting with a different emoji adds a separate row, so one user can have several simultaneous
/// reactions on the same message. Unique on (MessageId, UserId, Emoji).</summary>
public class MessageReaction : BaseEntity
{
    public Guid Id { get; set; }

    public Guid MessageId { get; set; }
    public Guid UserId { get; set; }

    public string Emoji { get; set; } = string.Empty;
}
