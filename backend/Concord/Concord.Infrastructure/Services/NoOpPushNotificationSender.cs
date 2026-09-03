using Concord.Application.Push;
using Microsoft.Extensions.Logging;

namespace Concord.Infrastructure.Services;

/// <summary>
/// The only registered <see cref="IPushNotificationSender"/> for now - there is no Firebase/APNs
/// credential anywhere in this codebase to back a real implementation. This exists purely so the
/// token-storage endpoints (<c>PushTokensService</c>) and call sites that will eventually send a push
/// have a seam to depend on, without inventing placeholder credentials for a provider that isn't
/// configured.
/// </summary>
public class NoOpPushNotificationSender(ILogger<NoOpPushNotificationSender> logger) : IPushNotificationSender
{
    private readonly ILogger<NoOpPushNotificationSender> _logger = logger;

    public Task SendAsync(Guid userId, string title, string body)
    {
        _logger.LogDebug("would send push to {UserId}: {Title}", userId, title);

        return Task.CompletedTask;
    }
}
