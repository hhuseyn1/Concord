namespace Concord.Application.Push;

public interface IPushNotificationSender
{
    Task SendAsync(Guid userId, string title, string body);
}
