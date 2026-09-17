using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0/Servers/{serverId:guid}/Roles")]
[Authorize]
public class RolesController(RolesService rolesService) : BaseApiController
{
    private readonly RolesService _rolesService = rolesService;

    [HttpGet]
    public async Task<List<RoleResponse>> GetRolesAsync(Guid serverId)
    {
        return await _rolesService.GetRolesAsync(GetUserId(), serverId);
    }

    [HttpGet("Me")]
    public async Task<MyServerPermissionsResponse> GetMyPermissionsAsync(Guid serverId)
    {
        return await _rolesService.GetMyPermissionsAsync(GetUserId(), serverId);
    }

    [HttpPost]
    public async Task<RoleResponse> CreateRoleAsync(Guid serverId, CreateRoleRequest request)
    {
        return await _rolesService.CreateRoleAsync(GetUserId(), serverId, request);
    }

    [HttpPut("{roleId:guid}")]
    public async Task<RoleResponse> UpdateRoleAsync(Guid serverId, Guid roleId, UpdateRoleRequest request)
    {
        return await _rolesService.UpdateRoleAsync(GetUserId(), serverId, roleId, request);
    }

    [HttpDelete("{roleId:guid}")]
    public async Task DeleteRoleAsync(Guid serverId, Guid roleId)
    {
        await _rolesService.DeleteRoleAsync(GetUserId(), serverId, roleId);
    }

    [HttpPost("Reorder")]
    public async Task ReorderRolesAsync(Guid serverId, ReorderRolesRequest request)
    {
        await _rolesService.ReorderRolesAsync(GetUserId(), serverId, request);
    }

    [HttpGet("/Api/V1.0/Servers/{serverId:guid}/Members/{userId:guid}/Roles")]
    public async Task<List<RoleResponse>> GetMemberRolesAsync(Guid serverId, Guid userId)
    {
        return await _rolesService.GetMemberRolesAsync(GetUserId(), serverId, userId);
    }

    [HttpPut("/Api/V1.0/Servers/{serverId:guid}/Members/{userId:guid}/Roles/{roleId:guid}")]
    public async Task AssignRoleAsync(Guid serverId, Guid userId, Guid roleId)
    {
        await _rolesService.AssignRoleAsync(GetUserId(), serverId, userId, roleId);
    }

    [HttpDelete("/Api/V1.0/Servers/{serverId:guid}/Members/{userId:guid}/Roles/{roleId:guid}")]
    public async Task RemoveRoleAsync(Guid serverId, Guid userId, Guid roleId)
    {
        await _rolesService.RemoveRoleAsync(GetUserId(), serverId, userId, roleId);
    }
}
