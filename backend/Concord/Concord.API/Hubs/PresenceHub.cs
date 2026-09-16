using System.IdentityModel.Tokens.Jwt;
using Concord.Application.Enums;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Concord.API.Hubs;

[Authorize]
public class PresenceHub(PresenceService presenceService) : Hub
{
    private readonly PresenceService _presenceService = presenceService;

    public override async Task OnConnectedAsync()
    {
        try
        {
            var claimedUserId = Context.User?.Claims.FirstOrDefault(claim => claim.Type == JwtRegisteredClaimNames.Sub)?.Value;
            var userId = Guid.TryParse(claimedUserId, out Guid parsedUserId) ? parsedUserId : throw new UnauthorizedAccessException();

            var status = await _presenceService.HandleConnectAsync(userId);

            if (status.HasValue)
            {
                var audience = await _presenceService.GetAudienceAsync(userId);

                await Clients.Users(audience.Select(id => id.ToString()).ToList())
                    .SendAsync("PresenceChanged", new { userId, status = PresenceService.ToVisibleStatus(status.Value), lastSeenAt = (DateTime?)null });
            }

            await base.OnConnectedAsync();
        }
        catch (Exception ex)
        {
            throw new HubException(ex.Message);
        }
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        try
        {
            var claimedUserId = Context.User?.Claims.FirstOrDefault(claim => claim.Type == JwtRegisteredClaimNames.Sub)?.Value;
            var userId = Guid.TryParse(claimedUserId, out Guid parsedUserId) ? parsedUserId : throw new UnauthorizedAccessException();

            var status = await _presenceService.HandleDisconnectAsync(userId);

            if (status.HasValue)
            {
                var audience = await _presenceService.GetAudienceAsync(userId);

                await Clients.Users(audience.Select(id => id.ToString()).ToList())
                    .SendAsync("PresenceChanged", new { userId, status = status.Value, lastSeenAt = DateTime.UtcNow });
            }

            await base.OnDisconnectedAsync(exception);
        }
        catch (Exception ex)
        {
            throw new HubException(ex.Message);
        }
    }

    /// <summary>
    /// Called periodically by clients while connected, purely to keep the Redis connection-count
    /// key (see <see cref="PresenceService.RenewConnectionAsync"/>) from expiring under a
    /// long-lived, otherwise-idle connection. Not part of the visible presence status itself.
    /// </summary>
    public async Task Heartbeat()
    {
        try
        {
            var claimedUserId = Context.User?.Claims.FirstOrDefault(claim => claim.Type == JwtRegisteredClaimNames.Sub)?.Value;
            var userId = Guid.TryParse(claimedUserId, out Guid parsedUserId) ? parsedUserId : throw new UnauthorizedAccessException();

            await _presenceService.RenewConnectionAsync(userId);
        }
        catch (Exception ex)
        {
            throw new HubException(ex.Message);
        }
    }

    public async Task SetStatus(PresenceStatus status)
    {
        try
        {
            var claimedUserId = Context.User?.Claims.FirstOrDefault(claim => claim.Type == JwtRegisteredClaimNames.Sub)?.Value;
            var userId = Guid.TryParse(claimedUserId, out Guid parsedUserId) ? parsedUserId : throw new UnauthorizedAccessException();

            await _presenceService.SetStatusAsync(userId, status);

            var audience = await _presenceService.GetAudienceAsync(userId);

            await Clients.Users(audience.Select(id => id.ToString()).ToList())
                .SendAsync("PresenceChanged", new { userId, status = PresenceService.ToVisibleStatus(status), lastSeenAt = (DateTime?)null });
        }
        catch (Exception ex)
        {
            throw new HubException(ex.Message);
        }
    }
}
