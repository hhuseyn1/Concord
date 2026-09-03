using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


/// <summary>
/// Ban, mute, and timeout (P1). Kick lives on <see cref="ServersController"/> as
/// <c>DELETE Servers/{id}/Members/{userId}</c> and is not duplicated here.
/// </summary>
[Route("Api/V1.0/Servers/{serverId:guid}")]
[Authorize]
public class ModerationController(ModerationService moderationService) : BaseApiController
{
    private readonly ModerationService _moderationService = moderationService;

    [HttpGet("Bans")]
    public async Task<PagedResult<ServerBanResponse>> GetBansAsync(Guid serverId, [FromQuery] int page, [FromQuery] int pageSize)
    {
        return await _moderationService.GetBansAsync(GetUserId(), serverId, page, pageSize);
    }

    [HttpPut("Bans/{userId:guid}")]
    public async Task BanMemberAsync(Guid serverId, Guid userId, BanMemberRequest request)
    {
        await _moderationService.BanMemberAsync(GetUserId(), serverId, userId, request);
    }

    [HttpDelete("Bans/{userId:guid}")]
    public async Task UnbanUserAsync(Guid serverId, Guid userId)
    {
        await _moderationService.UnbanUserAsync(GetUserId(), serverId, userId);
    }

    [HttpGet("Members/{userId:guid}/Moderation")]
    public async Task<MemberModerationResponse> GetMemberModerationAsync(Guid serverId, Guid userId)
    {
        return await _moderationService.GetMemberModerationAsync(GetUserId(), serverId, userId);
    }

    [HttpPut("Members/{userId:guid}/Mute")]
    public async Task<MemberModerationResponse> MuteMemberAsync(Guid serverId, Guid userId)
    {
        return await _moderationService.SetMuteAsync(GetUserId(), serverId, userId, muted: true);
    }

    [HttpDelete("Members/{userId:guid}/Mute")]
    public async Task<MemberModerationResponse> UnmuteMemberAsync(Guid serverId, Guid userId)
    {
        return await _moderationService.SetMuteAsync(GetUserId(), serverId, userId, muted: false);
    }

    [HttpPut("Members/{userId:guid}/Timeout")]
    public async Task<MemberModerationResponse> TimeoutMemberAsync(Guid serverId, Guid userId, TimeoutMemberRequest request)
    {
        return await _moderationService.TimeoutMemberAsync(GetUserId(), serverId, userId, request);
    }

    [HttpDelete("Members/{userId:guid}/Timeout")]
    public async Task<MemberModerationResponse> RemoveTimeoutAsync(Guid serverId, Guid userId)
    {
        return await _moderationService.RemoveTimeoutAsync(GetUserId(), serverId, userId);
    }
}
