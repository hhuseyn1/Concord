namespace Concord.Application.Push;

/// <summary>
/// The seam a real push provider (FCM/APNs) would implement. No such provider is wired up yet - there
/// are no push credentials anywhere in this codebase - so the only registered implementation is
/// <c>NoOpPushNotificationSender</c>. Not called from <c>NotificationsService</c>'s existing sites
/// (mentions/friend-requests/missed-calls) yet; that wiring is a follow-up once a real sender exists.
/// </summary>
public interface IPushNotificationSender
{
    Task SendAsync(Guid userId, string title, string body);
}
