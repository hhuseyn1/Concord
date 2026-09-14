using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


/// <summary>
/// The report/flag system and moderator queue. <c>POST Reports</c> is open to any authenticated user;
/// the <c>Admin/Reports</c> routes mirror <see cref="AdminController"/>'s exact gate
/// (<c>[Authorize(Roles = "Admin")]</c> against the global site-admin role, unrelated to server-scoped
/// RBAC).
/// </summary>
[Route("Api/V1.0")]
[Authorize]
public class ReportsController(ReportsService reportsService) : BaseApiController
{
    private readonly ReportsService _reportsService = reportsService;

    [HttpPost("Reports")]
    public async Task<ReportResponse> CreateReportAsync(CreateReportRequest request)
    {
        return await _reportsService.CreateReportAsync(GetUserId(), request);
    }

    [HttpGet("Admin/Reports")]
    [Authorize(Roles = "Admin")]
    public async Task<PagedResult<ReportResponse>> GetReportsAsync(
        [FromQuery] int page,
        [FromQuery] int pageSize,
        [FromQuery] ReportStatus? status,
        [FromQuery] string? search,
        [FromQuery] string? sortBy,
        [FromQuery] string? sortDirection)
    {
        return await _reportsService.GetReportsAsync(page, pageSize, status, search, sortBy, sortDirection);
    }

    [HttpPost("Admin/Reports/{reportId:guid}:Resolve")]
    [Authorize(Roles = "Admin")]
    public async Task ResolveReportAsync(Guid reportId)
    {
        await _reportsService.ResolveReportAsync(GetUserId(), reportId);
    }

    [HttpPost("Admin/Reports/{reportId:guid}:Dismiss")]
    [Authorize(Roles = "Admin")]
    public async Task DismissReportAsync(Guid reportId, [FromBody] DismissReportRequest? request)
    {
        await _reportsService.DismissReportAsync(GetUserId(), reportId, request?.Reason);
    }
}
