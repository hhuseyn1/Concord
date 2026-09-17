using Concord.Application.Models;
using Concord.Domain.Entities;

namespace Concord.Infrastructure.Extensions;

public static class ModerationExtensions
{
    public static ServerBanResponse MapToResponse(this ServerBan ban, User user) => new()
    {
        User = user.MapToPublicModel(null),
        BannedByUserId = ban.BannedByUserId,
        Reason = ban.Reason,
        ExpiresAtUtc = ban.ExpiresAtUtc,
        BannedAt = ban.Created
    };

    public static MemberModerationResponse MapToModerationResponse(this ServerMember member)
    {
        var isTimedOut = member.TimedOutUntil is { } until && until > DateTime.UtcNow;

        return new MemberModerationResponse
        {
            UserId = member.UserId,
            IsMuted = member.IsMuted,
            TimedOutUntil = isTimedOut ? member.TimedOutUntil : null,
            TimedOutByUserId = isTimedOut ? member.TimedOutByUserId : null,
            TimeoutReason = isTimedOut ? member.TimeoutReason : null
        };
    }
}
