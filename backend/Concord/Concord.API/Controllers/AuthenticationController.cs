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

    /// <summary>
    /// Password step. When the account has a second factor the response carries
    /// <c>TwoFactorRequired</c> and a short-lived <c>TwoFactorToken</c> instead of a session - finish
    /// at <c>Login/TwoFactor</c>.
    /// </summary>
    [HttpPost("Login")]
    public async Task<TokenResponse> LoginAsync(LoginRequest request)
    {
        return await _authenticationService.LoginAsync(request);
    }

    /// <summary>
    /// Second-factor step. Accepts a TOTP code or an unused recovery code. Shares the login rate
    /// limit, since it is the same credential-guessing surface.
    /// </summary>
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

    /// <summary>
    /// Begins enrolment: mints a secret and returns it as a QR plus a typeable key. Two-factor is not
    /// yet active - the secret stays inert until confirmed at <c>Me/TwoFactor/Enable</c>.
    /// </summary>
    [HttpPost("Me/TwoFactor/Setup")]
    [Authorize]
    public async Task<TwoFactorSetupResponse> StartTwoFactorSetupAsync()
    {
        return await _twoFactorService.StartSetupAsync(GetUserId());
    }

    /// <summary>
    /// Confirms enrolment with a code from the authenticator and returns the recovery codes. Those
    /// codes are shown exactly once - only their hashes are kept.
    /// </summary>
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