using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0/Sessions")]
[Authorize]
public class SessionsController(SessionsService sessionsService) : BaseApiController
{
    private readonly SessionsService _sessionsService = sessionsService;

    [HttpGet]
    public async Task<List<SessionResponse>> GetMySessionsAsync()
    {
        return await _sessionsService.GetMySessionsAsync(GetUserId(), GetSessionId());
    }

    [HttpDelete("Current")]
    public async Task RevokeCurrentSessionAsync()
    {
        await _sessionsService.RevokeCurrentSessionAsync(GetUserId(), GetSessionId());
    }

    [HttpDelete("Others")]
    public async Task RevokeOtherSessionsAsync()
    {
        await _sessionsService.RevokeOtherSessionsAsync(GetUserId(), GetSessionId());
    }

    [HttpDelete("{sessionId:guid}")]
    public async Task RevokeSessionAsync(Guid sessionId)
    {
        await _sessionsService.RevokeSessionAsync(GetUserId(), sessionId);
    }
}
