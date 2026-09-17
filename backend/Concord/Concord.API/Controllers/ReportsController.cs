using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


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
    public async Task<PagedResult<ReportResponse>> GetReportsAsync([FromQuery] GetReportsRequest request)
    {
        return await _reportsService.GetReportsAsync(request);
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
