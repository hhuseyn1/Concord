using Concord.Application.Models;
using Concord.Domain.Entities;

namespace Concord.Infrastructure.Extensions;

public static class SessionExtensions
{
    public static SessionResponse MapToResponse(this Session session, Guid currentSessionId) => new()
    {
        Id = session.Id,
        DeviceLabel = session.DeviceLabel,
        Browser = session.Browser,
        OS = session.OS,
        IpAddress = session.IpAddress,
        Created = session.Created,
        LastActiveAt = session.Refreshed ?? session.Created,
        IsCurrent = session.Id == currentSessionId
    };
}
