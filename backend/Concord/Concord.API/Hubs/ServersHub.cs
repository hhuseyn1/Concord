using System.IdentityModel.Tokens.Jwt;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Concord.API.Hubs;

[Authorize]
public class ServersHub(ServersService serversService) : Hub
{
    private readonly ServersService _serversService = serversService;

    public async Task JoinServer(Guid serverId)
    {
        try
        {
            var claimedUserId = Context.User?.Claims.FirstOrDefault(claim => claim.Type == JwtRegisteredClaimNames.Sub)?.Value;
            var userId = Guid.TryParse(claimedUserId, out Guid parsedUserId) ? parsedUserId : throw new UnauthorizedAccessException();

            await _serversService.AssertServerMemberAsync(userId, serverId);

            await Groups.AddToGroupAsync(Context.ConnectionId, $"Server:{serverId}");
        }
        catch (Exception ex)
        {
            throw new HubException(ex.Message);
        }
    }

    public async Task LeaveServer(Guid serverId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Server:{serverId}");
    }
}
