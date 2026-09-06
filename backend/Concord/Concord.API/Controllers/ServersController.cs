using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0/Servers")]
[Authorize]
public class ServersController(ServersService serversService) : BaseApiController
{
    private readonly ServersService _serversService = serversService;

    [HttpPost]
    public async Task<ServerResponse> CreateServerAsync(CreateServerRequest request)
    {
        return await _serversService.CreateServerAsync(GetUserId(), request);
    }

    [HttpGet]
    public async Task<List<ServerSummary>> GetMyServersAsync()
    {
        return await _serversService.GetMyServersAsync(GetUserId());
    }

    [HttpPut("{serverId:guid}")]
    public async Task<ServerResponse> UpdateServerAsync(Guid serverId, UpdateServerRequest request)
    {
        return await _serversService.UpdateServerAsync(GetUserId(), serverId, request);
    }

    [HttpPost("Join/{inviteCode}")]
    public async Task<ServerResponse> JoinServerAsync(string inviteCode)
    {
        var (server, joinedNow) = await _serversService.JoinServerAsync(GetUserId(), inviteCode);
        server.JoinedNow = joinedNow;
        return server;
    }

    [HttpDelete("{serverId:guid}/Members/Me")]
    public async Task LeaveServerAsync(Guid serverId)
    {
        await _serversService.LeaveServerAsync(GetUserId(), serverId);
    }

    [HttpDelete("{serverId:guid}/Members/{userId:guid}")]
    public async Task RemoveMemberAsync(Guid serverId, Guid userId)
    {
        await _serversService.RemoveMemberAsync(GetUserId(), serverId, userId);
    }

    [HttpDelete("{serverId:guid}")]
    public async Task DeleteServerAsync(Guid serverId)
    {
        await _serversService.DeleteServerAsync(GetUserId(), serverId);
    }

    [HttpPost("{serverId:guid}/Ownership/Transfer")]
    public async Task TransferOwnershipAsync(Guid serverId, TransferOwnershipRequest request)
    {
        await _serversService.TransferOwnershipAsync(GetUserId(), serverId, request);
    }

    [HttpGet("{serverId:guid}/Members")]
    public async Task<PagedResult<ServerMemberSummary>> GetMembersAsync(Guid serverId, [FromQuery] int page, [FromQuery] int pageSize)
    {
        return await _serversService.GetMembersAsync(GetUserId(), serverId, page, pageSize);
    }

    [HttpPost("{serverId:guid}/Invites")]
    public async Task<InviteResponse> GenerateInviteAsync(Guid serverId, GenerateInviteRequest request)
    {
        return await _serversService.GenerateInviteAsync(GetUserId(), serverId, request);
    }

    [HttpGet("{serverId:guid}/Invites")]
    public async Task<List<InviteResponse>> ListInvitesAsync(Guid serverId)
    {
        return await _serversService.ListInvitesAsync(GetUserId(), serverId);
    }
}
