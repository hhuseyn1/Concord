namespace Concord.Domain.Entities;

/// <summary>Per-user last-read marker for a channel (M-04), mirroring <c>Conversation</c>'s
/// <c>LastReadAtA</c>/<c>LastReadAtB</c> but as its own join row rather than two fixed columns, since a
/// channel (unlike a DM) has an unbounded number of members. Absence of a row for a given
/// (ChannelId, UserId) pair means "never read" - see <c>ChannelsService.GetUnreadCountAsync</c>.</summary>
public class ChannelReadState : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ChannelId { get; set; }
    public Guid UserId { get; set; }

    public DateTime LastReadAtUtc { get; set; }
}
