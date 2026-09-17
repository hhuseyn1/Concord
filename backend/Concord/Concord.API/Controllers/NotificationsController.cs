using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0/Notifications")]
[Authorize]
public class NotificationsController(NotificationsService notificationsService) : BaseApiController
{
    private readonly NotificationsService _notificationsService = notificationsService;

    [HttpGet]
    public async Task<PagedResult<NotificationResponse>> GetMyNotificationsAsync(int page, int pageSize)
    {
        return await _notificationsService.GetMyNotificationsAsync(GetUserId(), page, pageSize);
    }

    [HttpPost("{notificationId:guid}:Read")]
    public async Task MarkAsReadAsync(Guid notificationId)
    {
        await _notificationsService.MarkAsReadAsync(GetUserId(), notificationId);
    }

    [HttpPost("Read")]
    public async Task MarkAllAsReadAsync()
    {
        await _notificationsService.MarkAllAsReadAsync(GetUserId());
    }
}
