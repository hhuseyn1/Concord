using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;

[Route("Api/V1.0/QrLogin")]
public class QrLoginController(QrLoginService qrLoginService) : BaseApiController
{
    private readonly QrLoginService _qrLoginService = qrLoginService;

    [HttpPost("Sessions")]
    [AllowAnonymous]
    public async Task<QrLoginStartResponse> StartAsync()
    {
        return await _qrLoginService.StartAsync();
    }

    [HttpGet("Sessions/Status")]
    [AllowAnonymous]
    public async Task<QrLoginStatusResponse> GetStatusAsync(string pollingToken)
    {
        return await _qrLoginService.GetStatusAsync(pollingToken);
    }

    [HttpGet("Requests/{userCode}")]
    [Authorize]
    public async Task<QrLoginRequestInfoResponse> GetRequestInfoAsync(string userCode)
    {
        return await _qrLoginService.GetRequestInfoAsync(userCode);
    }

    [HttpPost("Requests/{userCode}/Approve")]
    [Authorize]
    public async Task ApproveAsync(string userCode)
    {
        await _qrLoginService.ApproveAsync(GetUserId(), userCode);
    }

    [HttpPost("Requests/{userCode}/Deny")]
    [Authorize]
    public async Task DenyAsync(string userCode)
    {
        await _qrLoginService.DenyAsync(GetUserId(), userCode);
    }
}
