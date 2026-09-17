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
