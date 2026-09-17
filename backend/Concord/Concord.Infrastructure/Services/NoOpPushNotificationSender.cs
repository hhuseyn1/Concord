using Concord.Application.Push;
using Microsoft.Extensions.Logging;

namespace Concord.Infrastructure.Services;

public class NoOpPushNotificationSender(ILogger<NoOpPushNotificationSender> logger) : IPushNotificationSender
{
    private readonly ILogger<NoOpPushNotificationSender> _logger = logger;

    public Task SendAsync(Guid userId, string title, string body)
    {
        _logger.LogDebug("would send push to {UserId}: {Title}", userId, title);

        return Task.CompletedTask;
    }
}
