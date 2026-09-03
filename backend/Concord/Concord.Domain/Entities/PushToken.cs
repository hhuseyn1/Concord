using Concord.Application.Enums;

namespace Concord.Domain.Entities;

/// <summary>
/// A device's push-notification registration. <see cref="Token"/> carries a unique index rather than
/// a composite (UserId, Token) key: the token is assigned by the OS/push service to a device
/// installation, not to whichever account happens to be signed in, so a re-registration under a
/// different user (logout/login on the same device) reassigns the existing row's <see cref="UserId"/>
/// instead of creating a second one - see <c>PushTokensService.RegisterAsync</c>.
/// </summary>
public class PushToken : BaseEntity
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string Token { get; set; } = null!;

    public PushPlatform Platform { get; set; }

    public DateTime LastSeenUtc { get; set; }
}
