using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


/// <summary>
/// Site-wide admin surface (P4). Every endpoint requires <c>Roles.Admin</c> - the same global role
/// already used for <see cref="AuthenticationController.ResetPasswordAsync"/>, unrelated to the
/// server-scoped RBAC from P0.
/// </summary>
[Route("Api/V1.0/Admin")]
[Authorize(Roles = "Admin")]
public class AdminController(AdminService adminService) : BaseApiController
{
    private readonly AdminService _adminService = adminService;

    [HttpGet("Overview")]
    public async Task<AdminOverviewResponse> GetOverviewAsync()
    {
        return await _adminService.GetOverviewAsync();
    }

    [HttpGet("Overview/Charts")]
    public async Task<AdminOverviewChartsResponse> GetOverviewChartsAsync([FromQuery] DateTime? fromUtc, [FromQuery] DateTime? toUtc)
    {
        return await _adminService.GetOverviewChartsAsync(fromUtc, toUtc);
    }

    [HttpGet("Overview/UserGrowth")]
    public async Task<List<AdminUserGrowthPoint>> GetUserGrowthAsync([FromQuery] int? year)
    {
        return await _adminService.GetUserGrowthAsync(year);
    }

    [HttpGet("Users")]
    public async Task<PagedResult<AdminUserSummary>> GetUsersAsync(
        [FromQuery] int page,
        [FromQuery] int pageSize,
        [FromQuery] string? search,
        [FromQuery] string? sortBy,
        [FromQuery] string? sortDirection)
    {
        return await _adminService.GetUsersAsync(page, pageSize, search, sortBy, sortDirection);
    }

    [HttpPost("Users/{userId:guid}/Disable")]
    public async Task DisableUserAsync(Guid userId)
    {
        await _adminService.DisableUserAsync(GetUserId(), userId);
    }

    [HttpPost("Users/{userId:guid}/Enable")]
    public async Task EnableUserAsync(Guid userId)
    {
        await _adminService.EnableUserAsync(GetUserId(), userId);
    }

    [HttpPut("Users/{userId:guid}/Role")]
    public async Task SetUserRoleAsync(Guid userId, SetUserRoleRequest request)
    {
        await _adminService.SetUserRoleAsync(GetUserId(), userId, request.Role);
    }

    [HttpGet("Subscriptions")]
    public async Task<PagedResult<AdminSubscriptionSummary>> GetSubscriptionsAsync(
        [FromQuery] int page,
        [FromQuery] int pageSize,
        [FromQuery] SubscriptionStatus? status,
        [FromQuery] string? search,
        [FromQuery] string? sortBy,
        [FromQuery] string? sortDirection,
        [FromQuery] DateTime? fromUtc,
        [FromQuery] DateTime? toUtc)
    {
        return await _adminService.GetSubscriptionsAsync(page, pageSize, status, search, sortBy, sortDirection, fromUtc, toUtc);
    }

    [HttpGet("AuditLog")]
    public async Task<PagedResult<AuditLogResponse>> GetAuditLogAsync(
        [FromQuery] int page,
        [FromQuery] int pageSize,
        [FromQuery] string? actorEmail,
        [FromQuery] string? action,
        [FromQuery] DateTime? fromUtc,
        [FromQuery] DateTime? toUtc,
        [FromQuery] string? sortDirection)
    {
        return await _adminService.GetAuditLogAsync(page, pageSize, actorEmail, action, fromUtc, toUtc, sortDirection);
    }
}
