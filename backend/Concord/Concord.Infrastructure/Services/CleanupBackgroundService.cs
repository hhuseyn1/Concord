using Concord.Application.Models;
using Concord.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Concord.Infrastructure.Services;

/// <summary>
/// Hourly sweep for rows whose lifetime has already ended. None of this is a correctness
/// requirement - every one of these is evaluated on read elsewhere (see e.g.
/// <c>ModerationService.IsBannedAsync</c> and <see cref="ServerMember.TimedOutUntil"/>'s own
/// remarks) - this exists purely so expired/stale rows do not accumulate forever. A single
/// <see cref="PeriodicTimer"/> is enough for that; this codebase has no scheduler dependency and
/// does not need one for a once-an-hour job.
///
/// Uses <see cref="IServiceScopeFactory"/> rather than an injected <c>ApplicationDbContext</c>
/// because a <see cref="BackgroundService"/> is a singleton but <c>ApplicationDbContext</c> is
/// scoped - a fresh scope is created for every run.
/// </summary>
public class CleanupBackgroundService(
    IServiceScopeFactory scopeFactory,
    ILogger<CleanupBackgroundService> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromHours(1);

    private readonly IServiceScopeFactory _scopeFactory = scopeFactory;
    private readonly ILogger<CleanupBackgroundService> _logger = logger;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval);

        do
        {
            try
            {
                await RunOnceAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                // A failed sweep (e.g. a transient DB blip) should not take the timer down - the
                // next tick tries again an hour later.
                _logger.LogError(ex, "Cleanup sweep failed");
            }
        }
        while (await timer.WaitForNextTickAsync(stoppingToken));
    }

    private async Task RunOnceAsync(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        var now = DateTime.UtcNow;

        var purgedQrLoginSessions = await context.QrLoginSessions
            .Where(session => session.ExpiresAtUtc < now)
            .ExecuteDeleteAsync(cancellationToken);

        var purgedPasswordResetTokens = await context.PasswordResetTokens
            .Where(token => token.ExpiresAt < now)
            .ExecuteDeleteAsync(cancellationToken);

        var purgedEmailVerificationTokens = await context.EmailVerificationTokens
            .Where(token => token.ExpiresAt < now)
            .ExecuteDeleteAsync(cancellationToken);

        var purgedSessions = await context.Sessions
            .Where(session => session.Expires < now)
            .ExecuteDeleteAsync(cancellationToken);

        // ExpiresAtUtc == null is a permanent ban - excluded, never purged.
        var purgedServerBans = await context.ServerBans
            .Where(ban => ban.ExpiresAtUtc != null && ban.ExpiresAtUtc < now)
            .ExecuteDeleteAsync(cancellationToken);

        // A timeout is moderation state on an existing membership, not a row to purge: only the
        // timeout fields are cleared, mirroring ModerationService.RemoveTimeoutAsync's own reset of
        // all three together, and the ServerMember row itself is left untouched.
        var clearedTimeouts = await context.ServerMembers
            .Where(member => member.TimedOutUntil != null && member.TimedOutUntil < now)
            .ExecuteUpdateAsync(setters => setters
                    .SetProperty(member => member.TimedOutUntil, (DateTime?)null)
                    .SetProperty(member => member.TimedOutByUserId, (Guid?)null)
                    .SetProperty(member => member.TimeoutReason, (string?)null),
                cancellationToken);

        // Self-service account deletion (see UsersService.RequestAccountDeletionAsync): the grace
        // period has lapsed with no cancelling login, so the account is anonymized for good. This is
        // deliberately an update, not a delete - other users' messages/memberships likely carry
        // non-nullable FKs to this UserId, and hard-deleting the row would cascade or violate
        // referential integrity. Disabled is left set (permanently blocks/hides the account
        // everywhere that already checks it) but DeletionRequestedAt is cleared, so
        // AuthenticationService.IsBlockedFromLoggingIn no longer treats it as cancellable.
        var deletionCutoff = now.AddDays(-GlobalConstants.AccountDeletionGracePeriodDays);

        var purgedUsers = await context.Users
            .Where(user => user.DeletionRequestedAt != null && user.DeletionRequestedAt < deletionCutoff)
            .ExecuteUpdateAsync(setters => setters
                    .SetProperty(user => user.Email, (string?)null)
                    .SetProperty(user => user.PhoneNumber, (string?)null)
                    .SetProperty(user => user.Username, (string?)null)
                    .SetProperty(user => user.AvatarUrl, (string?)null)
                    .SetProperty(user => user.Password, (string?)null)
                    .SetProperty(user => user.TwoFactorSecret, (string?)null)
                    .SetProperty(user => user.TwoFactorEnabled, false)
                    .SetProperty(user => user.Name, "Deleted")
                    .SetProperty(user => user.Surname, "User")
                    .SetProperty(user => user.DeletionRequestedAt, (DateTime?)null),
                cancellationToken);

        _logger.LogInformation(
            "Cleanup sweep: purged {QrLoginSessions} QR login session(s), {PasswordResetTokens} password reset token(s), " +
            "{EmailVerificationTokens} email verification token(s), {Sessions} session(s), {ServerBans} expired server ban(s), " +
            "{Users} deleted user(s) past their grace period; cleared {Timeouts} lapsed member timeout(s)",
            purgedQrLoginSessions, purgedPasswordResetTokens, purgedEmailVerificationTokens, purgedSessions, purgedServerBans, purgedUsers, clearedTimeouts);
    }
}
