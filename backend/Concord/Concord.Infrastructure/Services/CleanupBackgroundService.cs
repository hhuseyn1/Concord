using Concord.Application.Models;
using Concord.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Concord.Infrastructure.Services;

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

        var purgedServerBans = await context.ServerBans
            .Where(ban => ban.ExpiresAtUtc != null && ban.ExpiresAtUtc < now)
            .ExecuteDeleteAsync(cancellationToken);

        var clearedTimeouts = await context.ServerMembers
            .Where(member => member.TimedOutUntil != null && member.TimedOutUntil < now)
            .ExecuteUpdateAsync(setters => setters
                    .SetProperty(member => member.TimedOutUntil, (DateTime?)null)
                    .SetProperty(member => member.TimedOutByUserId, (Guid?)null)
                    .SetProperty(member => member.TimeoutReason, (string?)null),
                cancellationToken);

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
