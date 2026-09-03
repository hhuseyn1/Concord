using Concord.Application.Models;
using Concord.Domain.Entities;

namespace Concord.Infrastructure.Extensions;

public static class ServerExtensions
{
    public static ServerResponse MapToResponse(this Server server) => new()
    {
        Id = server.Id,
        Name = server.Name,
        OwnerId = server.OwnerId,
        IconUrl = server.IconUrl,
        Created = server.Created
    };

    public static ServerSummary MapToSummary(this Server server) => new()
    {
        Id = server.Id,
        Name = server.Name,
        OwnerId = server.OwnerId,
        IconUrl = server.IconUrl,
        Created = server.Created
    };
}
