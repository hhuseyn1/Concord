namespace Concord.Domain.Entities;

public class ChannelReadState : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ChannelId { get; set; }
    public Guid UserId { get; set; }

    public DateTime LastReadAtUtc { get; set; }
}
