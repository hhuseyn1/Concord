using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;

/// <summary>
/// Cross-device sign-in by QR code (P3).
///
/// The two unauthenticated endpoints - starting a request and polling it - are reachable without
/// credentials, and polling is called repeatedly by design; see the QrLogin rate limit in
/// Program.cs for the reasoning behind its generous, still-bounded threshold.
/// </summary>
[Route("Api/V1.0/QrLogin")]
public class QrLoginController(QrLoginService qrLoginService) : BaseApiController
{
    private readonly QrLoginService _qrLoginService = qrLoginService;

    /// <summary>
    /// Begins a request from a browser with no credentials. Returns the QR, the human-readable code,
    /// and the polling secret the caller must keep to itself.
    /// </summary>
    [HttpPost("Sessions")]
    [AllowAnonymous]
    public async Task<QrLoginStartResponse> StartAsync()
    {
        return await _qrLoginService.StartAsync();
    }

    /// <summary>
    /// Polled by the waiting browser. Returns the session exactly once, on the first call after
    /// approval.
    /// </summary>
    [HttpGet("Sessions/Status")]
    [AllowAnonymous]
    public async Task<QrLoginStatusResponse> GetStatusAsync([FromQuery] string pollingToken)
    {
        return await _qrLoginService.GetStatusAsync(pollingToken);
    }

    /// <summary>Details of the requesting device, shown on the approval screen. Authenticated.</summary>
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
