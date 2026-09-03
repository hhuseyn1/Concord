using Concord.Application.Enums;

namespace Concord.Domain.Entities;

public class Channel : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ServerId { get; set; }

    public string? Name { get; set; }

    public ChannelType Type { get; set; }

    /// <summary>Manual sort order within this channel's <see cref="ChannelType"/> group (P3). New
    /// channels append to the end of their group; see <c>ChannelsService.CreateChannelAsync</c> and
    /// <c>ChannelsService.ReorderChannelsAsync</c>. Does not group channels across types - Text and
    /// Voice remain two separate lists, each with its own 0-based ordering.</summary>
    public int Position { get; set; }
}
