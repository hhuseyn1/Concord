using Concord.Application.Models;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

/// <summary>
/// Registration-only half of push notifications (P4) - see <c>Application.Push.IPushNotificationSender</c>
/// for why no send integration exists yet.
/// </summary>
public class PushTokensService(ApplicationDbContext context)
{
    private readonly ApplicationDbContext _context = context;

    /// <summary>
    /// Upserts by <see cref="PushToken.Token"/> alone, not by (UserId, Token). A push token is issued
    /// by the OS/push service to a specific device installation, not to whichever account happens to
    /// be signed into it - if user A logs out and user B logs into the same device, the app will
    /// typically re-register the very same token under B. Upserting on (UserId, Token) would leave A's
    /// row in place, so both accounts would keep receiving pushes aimed at that device. Keying on the
    /// token alone reassigns the existing row's owner instead, matching a real device's write.
    /// </summary>
    public async Task RegisterAsync(Guid userId, RegisterPushTokenRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Token))
            throw new ParameterValidationException(nameof(request.Token));

        var existing = await _context.PushTokens.FirstOrDefaultAsync(token => token.Token == request.Token);

        if (existing is not null)
        {
            existing.UserId = userId;
            existing.Platform = request.Platform;
            existing.LastSeenUtc = DateTime.UtcNow;
        }
        else
        {
            _context.PushTokens.Add(new PushToken
            {
                UserId = userId,
                Token = request.Token,
                Platform = request.Platform,
                LastSeenUtc = DateTime.UtcNow
            });
        }

        await _context.SaveChangesAsync();
    }

    /// <summary>
    /// Idempotent by design, matching <c>SessionsService.RevokeCurrentSessionAsync</c> - a logout
    /// deregistration racing with (or repeating after) an already-removed token is not an error.
    /// Scoped to the caller's own token so one account cannot deregister a token that has since been
    /// reassigned to someone else's device.
    /// </summary>
    public async Task DeregisterAsync(Guid userId, string token)
    {
        await _context.PushTokens
            .Where(pushToken => pushToken.UserId == userId && pushToken.Token == token)
            .ExecuteDeleteAsync();
    }
}
