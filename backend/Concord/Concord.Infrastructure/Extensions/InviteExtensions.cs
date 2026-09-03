using Concord.Application.Models;
using Concord.Domain.Entities;

namespace Concord.Infrastructure.Extensions;

public static class InviteExtensions
{
    public static InviteResponse MapToResponse(this Invite invite) => new()
    {
        Code = invite.Code,
        ExpiresAtUtc = invite.ExpiresAtUtc,
        MaxUses = invite.MaxUses,
        UseCount = invite.UseCount
    };
}
