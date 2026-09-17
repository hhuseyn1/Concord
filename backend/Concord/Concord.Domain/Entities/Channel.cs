using Concord.Application.Enums;

namespace Concord.Domain.Entities;

public class Channel : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ServerId { get; set; }

    public string? Name { get; set; }

    public ChannelType Type { get; set; }

    public int Position { get; set; }
}
