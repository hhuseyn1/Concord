using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0")]
public class AuthenticationController(
    AuthenticationService authenticationService,
    TwoFactorService twoFactorService) : BaseApiController
{
    private readonly AuthenticationService _authenticationService = authenticationService;
    private readonly TwoFactorService _twoFactorService = twoFactorService;

    [HttpPost("Login")]
    public async Task<TokenResponse> LoginAsync(LoginRequest request)
    {
        return await _authenticationService.LoginAsync(request);
    }

    [HttpPost("Login/TwoFactor")]
    public async Task<TokenResponse> CompleteTwoFactorLoginAsync(TwoFactorLoginRequest request)
    {
        return await _authenticationService.CompleteTwoFactorLoginAsync(request);
    }

    [HttpPost("Register")]
    public async Task<TokenResponse> RegisterAsync(RegisterRequestBase request)
    {
        return await _authenticationService.RegisterAsync(request);
    }

    [HttpGet("Register/Username-available")]
    public async Task<UsernameAvailabilityResponse> CheckUsernameAvailableAsync(string username)
    {
        return await _authenticationService.CheckUsernameAvailableAsync(username);
    }

    [HttpPost("{userId}:Reset-password")]
    [Authorize(Roles = "Admin")]
    public async Task ResetPasswordAsync(Guid userId, [FromBody] ResetPasswordRequest request)
    {
        await _authenticationService.ResetPasswordAsync(userId, request, GetUserId());
    }

    [HttpPost("Refresh")]
    [AllowAnonymous]
    public async Task<TokenResponse> RefreshAsync(RefreshRequest request)
    {
        return await _authenticationService.RefreshAsync(request);
    }

    [HttpPost("Forgot-password")]
    [AllowAnonymous]
    public async Task ForgotPasswordAsync([FromBody] ForgotPasswordRequest request)
    {
        await _authenticationService.ForgotPasswordAsync(request);
    }

    [HttpPost("Reset-password")]
    [AllowAnonymous]
    public async Task ConfirmPasswordResetAsync([FromBody] ConfirmPasswordResetRequest request)
    {
        await _authenticationService.ConfirmPasswordResetAsync(request);
    }

    [HttpPost("Verify-email")]
    [AllowAnonymous]
    public async Task ConfirmEmailAsync([FromBody] ConfirmEmailRequest request)
    {
        await _authenticationService.ConfirmEmailAsync(request);
    }

    [HttpPost("Resend-verification-email")]
    [AllowAnonymous]
    public async Task ResendVerificationEmailAsync([FromBody] ResendVerificationEmailRequest request)
    {
        await _authenticationService.ResendVerificationEmailAsync(request);
    }

    [HttpPost("Me:Change-password")]
    [Authorize]
    public async Task ChangePasswordAsync([FromBody] ChangePasswordRequest request)
    {
        await _authenticationService.ChangePasswordAsync(GetUserId(), GetSessionId(), request);
    }

    [HttpGet("Me/TwoFactor")]
    [Authorize]
    public async Task<TwoFactorStatusResponse> GetTwoFactorStatusAsync()
    {
        return await _twoFactorService.GetStatusAsync(GetUserId());
    }

    [HttpPost("Me/TwoFactor/Setup")]
    [Authorize]
    public async Task<TwoFactorSetupResponse> StartTwoFactorSetupAsync()
    {
        return await _twoFactorService.StartSetupAsync(GetUserId());
    }

    [HttpPost("Me/TwoFactor/Enable")]
    [Authorize]
    public async Task<RecoveryCodesResponse> EnableTwoFactorAsync([FromBody] TwoFactorCodeRequest request)
    {
        return await _twoFactorService.EnableAsync(GetUserId(), request.Code);
    }

    [HttpPost("Me/TwoFactor/Disable")]
    [Authorize]
    public async Task DisableTwoFactorAsync([FromBody] DisableTwoFactorRequest request)
    {
        await _twoFactorService.DisableAsync(GetUserId(), request);
    }

    [HttpPost("Me/TwoFactor/Recovery-Codes")]
    [Authorize]
    public async Task<RecoveryCodesResponse> RegenerateRecoveryCodesAsync([FromBody] ConfirmPasswordRequest request)
    {
        return await _twoFactorService.RegenerateRecoveryCodesAsync(GetUserId(), request.Password);
    }
}