using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


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
    public async Task<AdminOverviewChartsResponse> GetOverviewChartsAsync(DateTime? fromUtc, DateTime? toUtc)
    {
        return await _adminService.GetOverviewChartsAsync(fromUtc, toUtc);
    }

    [HttpGet("Overview/UserGrowth")]
    public async Task<List<AdminUserGrowthPoint>> GetUserGrowthAsync(int? year)
    {
        return await _adminService.GetUserGrowthAsync(year);
    }

    [HttpGet("Users")]
    public async Task<PagedResult<AdminUserSummary>> GetUsersAsync([FromQuery] GetAdminUsersRequest request)
    {
        return await _adminService.GetUsersAsync(request);
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
    public async Task<PagedResult<AdminSubscriptionSummary>> GetSubscriptionsAsync([FromQuery] GetAdminSubscriptionsRequest request)
    {
        return await _adminService.GetSubscriptionsAsync(request);
    }

    [HttpGet("AuditLog")]
    public async Task<PagedResult<AuditLogResponse>> GetAuditLogAsync([FromQuery] GetAuditLogRequest request)
    {
        return await _adminService.GetAuditLogAsync(request);
    }
}
