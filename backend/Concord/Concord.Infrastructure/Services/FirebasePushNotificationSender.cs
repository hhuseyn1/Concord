using Concord.Application.Push;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Settings;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Concord.Infrastructure.Services;

/// <summary>
/// Real FCM sender, registered by <c>ServicesConfig</c> in place of <see cref="NoOpPushNotificationSender"/>
/// once <see cref="FirebaseSettings.ServiceAccountJson"/> is configured. A user can have more than one
/// registered <see cref="Domain.Entities.PushToken"/> (one per device install - see
/// <c>PushTokensService</c>'s remarks), so this fans a single logical notification out to all of them.
/// </summary>
public class FirebasePushNotificationSender : IPushNotificationSender
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<FirebasePushNotificationSender> _logger;
    private readonly FirebaseApp _app;

    public FirebasePushNotificationSender(
        ApplicationDbContext context,
        IOptions<FirebaseSettings> options,
        ILogger<FirebasePushNotificationSender> logger)
    {
        _context = context;
        _logger = logger;

        // FirebaseApp.Create throws if a default app already exists - reuse it rather than creating a
        // second one, since this sender is constructed once per request (scoped) but should share one
        // underlying app for the process lifetime.
        _app = FirebaseApp.DefaultInstance ?? FirebaseApp.Create(new AppOptions
        {
            Credential = CredentialFactory.FromJson<ServiceAccountCredential>(options.Value.ServiceAccountJson).ToGoogleCredential()
        });
    }

    public async Task SendAsync(Guid userId, string title, string body)
    {
        var tokens = await _context.PushTokens
            .Where(pushToken => pushToken.UserId == userId)
            .Select(pushToken => pushToken.Token)
            .ToListAsync();

        if (tokens.Count == 0) return;

        var messaging = FirebaseMessaging.GetMessaging(_app);
        var deadTokens = new List<string>();

        foreach (var token in tokens)
        {
            try
            {
                // Message.Token (not the newer Fid) is deliberate: PushTokensService/RegisterPushTokenRequest
                // store the classic FCM registration token the mobile client's getToken() call returns, not a
                // Firebase Installation ID - Fid targets a different, incompatible identifier.
#pragma warning disable CS0618
                await messaging.SendAsync(new Message
                {
                    Token = token,
                    Notification = new FirebaseAdmin.Messaging.Notification { Title = title, Body = body }
                });
#pragma warning restore CS0618
            }
            catch (FirebaseMessagingException ex) when (
                ex.MessagingErrorCode == MessagingErrorCode.Unregistered ||
                ex.MessagingErrorCode == MessagingErrorCode.InvalidArgument)
            {
                // The OS/app uninstall unregistered this token on Firebase's side, or it's stale
                // enough that FCM no longer recognizes it - either way, it'll never succeed again, so
                // drop it instead of retrying it on every future notification.
                deadTokens.Add(token);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to send a push notification to user {UserId}", userId);
            }
        }

        if (deadTokens.Count > 0)
        {
            await _context.PushTokens
                .Where(pushToken => deadTokens.Contains(pushToken.Token))
                .ExecuteDeleteAsync();
        }
    }
}
