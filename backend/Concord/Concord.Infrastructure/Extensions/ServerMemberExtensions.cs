using Concord.Application.Models;
using Concord.Domain.Entities;

namespace Concord.Infrastructure.Extensions;

public static class ServerMemberExtensions
{
    public static ServerMemberSummary MapToSummary(this ServerMember member, User user, UserPresence? presence) => new()
    {
        User = user.MapToPublicModel(presence),
        JoinedAt = member.Created,
        IsMuted = member.IsMuted,
        // Lapsed timeouts read as "not timed out" everywhere; see ModerationExtensions.
        TimedOutUntil = member.TimedOutUntil is { } until && until > DateTime.UtcNow ? until : null
    };
}
