using Concord.Application.Models;
using Concord.Domain.Entities;

namespace Concord.Infrastructure.Extensions;

public static class ChannelExtensions
{
    public static ChannelResponse MapToResponse(this Channel channel, int unreadCount = 0) => new()
    {
        Id = channel.Id,
        ServerId = channel.ServerId,
        Name = channel.Name,
        Type = channel.Type,
        Position = channel.Position,
        Created = channel.Created,
        UnreadCount = unreadCount
    };
}
