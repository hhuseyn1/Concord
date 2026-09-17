using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Concord.Application.Email;
using Concord.Application.Models;
using Concord.Domain.Entities;
using Concord.Domain.Enums;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Settings;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using UAParser;

namespace Concord.Infrastructure.Services;


public class AuthenticationService(
    ApplicationDbContext context,
    IOptions<AuthenticationSettings> authOptions,
    IOptions<EmailSettings> emailOptions,
    IEmailSender emailSender,
    TwoFactorService twoFactorService,
    IHttpContextAccessor httpContextAccessor,
    ILogger<AuthenticationService> logger)
{
    private const int MaxFailedLoginAttempts = 5;
    private static readonly TimeSpan LockoutDuration = TimeSpan.FromMinutes(15);
    private const int MinPasswordLength = 8;
    private const int PasswordResetTokenExpiresInMinutes = 30;
    private const int EmailVerificationTokenExpiresInMinutes = 60;

    /// <summary>Long enough to open an authenticator app, short enough that a leaked token is stale fast.</summary>
    private const int TwoFactorTokenExpiresInMinutes = 5;

    private const string TwoFactorPurposeClaim = "purpose";
    private const string TwoFactorPurposeValue = "two_factor";
    private const string TwoFactorRememberMeClaim = "remember_me";

    /// <summary>
    /// Distinct audience for the interstitial token. This is what makes it useless as an access
    /// token: <c>AuthConfig</c> validates against <c>AuthenticationSettings.Audience</c>, so a token
    /// minted for this audience fails there before any claim is inspected.
    /// </summary>
    private string TwoFactorTokenAudience => $"{_settings.Audience}:2fa";

    private readonly ApplicationDbContext _context = context;
    private readonly TwoFactorService _twoFactorService = twoFactorService;
    private readonly AuthenticationSettings _settings = authOptions.Value;
    private readonly EmailSettings _emailSettings = emailOptions.Value;
    private readonly IEmailSender _emailSender = emailSender;
    private readonly IHttpContextAccessor _httpContextAccessor = httpContextAccessor;
    private readonly ILogger<AuthenticationService> _logger = logger;

    public async Task<TokenResponse> LoginAsync(LoginRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email))
            throw new ParameterValidationException(nameof(request.Email));
        
        if (string.IsNullOrWhiteSpace(request.Password))
            throw new ParameterValidationException(nameof(request.Password));
        
        var user = await _context.Users
            .FirstOrDefaultAsync(user => user.Email == request.Email);

        if (user is null || IsBlockedFromLoggingIn(user))
            throw new UnauthorizedAccessException();

        if (user.LockoutEnd.HasValue && user.LockoutEnd > DateTime.UtcNow)
            throw new UserLockoutException(user.Id);
        
        if (string.IsNullOrWhiteSpace(user.Password))
            throw new UnauthorizedAccessException();

        var isPasswordValid = PasswordHasher.VerifyHashedPassword(user.Password, request.Password!);
        if (!isPasswordValid)
        {
            user.FailedLoginAttempts++;

            if (user.FailedLoginAttempts >= MaxFailedLoginAttempts)
            {
                user.LockoutEnd = DateTime.UtcNow.Add(LockoutDuration);
                _logger.LogWarning("Account {UserId} locked out after {Attempts} failed login attempts until {LockoutEnd}",
                    user.Id, user.FailedLoginAttempts, user.LockoutEnd);
            }

            await _context.SaveChangesAsync();

            throw new UnauthorizedAccessException();
        }

        user.FailedLoginAttempts = 0;
        user.LockoutEnd = null;

        if (PasswordHasher.NeedsRehash(user.Password))
            user.Password = PasswordHasher.HashPassword(request.Password!);

        await _context.SaveChangesAsync();

        // Unverified accounts can't log in at all - not even into the two-factor interstitial below,
        // since that would still leak "these credentials are correct" for an account that hasn't
        // proven the email is real yet.
        if (!user.EmailConfirmed)
            throw new EmailNotConfirmedException();

        // P2: with a second factor enrolled the password alone buys nothing but the right to try a
        // code. No Session row is created here, so there is no session to steal if the second step
        // is never completed.
        if (user.TwoFactorEnabled)
        {
            return new TokenResponse
            {
                TwoFactorRequired = true,
                TwoFactorToken = CreateTwoFactorToken(user, request.RememberMe)
            };
        }

        return await CreateNewSessionAsync(user, request.RememberMe);
    }

    /// <summary>
    /// Second step of a two-factor login: exchanges the short-lived token from
    /// <see cref="LoginAsync"/> plus a TOTP or recovery code for a real session.
    /// </summary>
    public async Task<TokenResponse> CompleteTwoFactorLoginAsync(TwoFactorLoginRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.TwoFactorToken))
            throw new ParameterValidationException(nameof(request.TwoFactorToken));

        var principal = GetPrincipalFromToken(request.TwoFactorToken, TwoFactorTokenAudience)
            ?? throw new UnauthorizedAccessException();

        // Belt and braces: the audience check above already rejects an access or refresh token here,
        // and this rejects anything minted for a different purpose under the same audience.
        if (principal.FindFirst(TwoFactorPurposeClaim)?.Value != TwoFactorPurposeValue)
            throw new UnauthorizedAccessException();

        var subject = principal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

        if (!Guid.TryParse(subject, out var userId))
            throw new UnauthorizedAccessException();

        var user = await _context.Users.FirstOrDefaultAsync(user => user.Id == userId);

        if (user is null || IsBlockedFromLoggingIn(user) || !user.TwoFactorEnabled)
            throw new UnauthorizedAccessException();

        if (user.LockoutEnd.HasValue && user.LockoutEnd > DateTime.UtcNow)
            throw new UserLockoutException(user.Id);

        // Defense in depth: LoginAsync no longer issues a two-factor token to an unverified account,
        // so this should be unreachable in practice, but a stale/edge-case token should never be
        // redeemable into a real session for one either.
        if (!user.EmailConfirmed)
            throw new EmailNotConfirmedException();

        if (!await _twoFactorService.VerifyForLoginAsync(user, request.Code))
        {
            // Wrong codes count toward the same lockout as wrong passwords; otherwise the second
            // factor would be the one credential on the account open to unlimited guessing.
            user.FailedLoginAttempts++;

            if (user.FailedLoginAttempts >= MaxFailedLoginAttempts)
            {
                user.LockoutEnd = DateTime.UtcNow.Add(LockoutDuration);
                _logger.LogWarning("Account {UserId} locked out after {Attempts} failed two-factor attempts until {LockoutEnd}",
                    user.Id, user.FailedLoginAttempts, user.LockoutEnd);
            }

            await _context.SaveChangesAsync();

            throw new InvalidTwoFactorCodeException();
        }

        user.FailedLoginAttempts = 0;
        user.LockoutEnd = null;

        await _context.SaveChangesAsync();

        // RememberMe is carried in the token rather than re-read from the request, so the second
        // step cannot quietly upgrade a session to persistent.
        var rememberMe = principal.FindFirst(TwoFactorRememberMeClaim)?.Value == bool.TrueString;

        return await CreateNewSessionAsync(user, rememberMe);
    }

    /// <summary>
    /// Mints the interstitial token for a pending two-factor login. It carries a distinct audience,
    /// so <c>AuthConfig</c>'s bearer scheme - which validates against the API audience - refuses it
    /// as an access token, and a five-minute lifetime.
    /// </summary>
    private string CreateTwoFactorToken(User user, bool rememberMe)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_settings.SigningKey!));

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim(TwoFactorPurposeClaim, TwoFactorPurposeValue),
            new Claim(TwoFactorRememberMeClaim, rememberMe ? bool.TrueString : bool.FalseString)
        };

        var token = new JwtSecurityToken(
            issuer: _settings.Issuer,
            audience: TwoFactorTokenAudience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(TwoFactorTokenExpiresInMinutes),
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256)
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public async Task<TokenResponse> RegisterAsync(RegisterRequestBase request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
            throw new ParameterValidationException(nameof(request.Name));

        if (string.IsNullOrWhiteSpace(request.Surname))
            throw new ParameterValidationException(nameof(request.Surname));

        if (!UsernamePolicy.IsValid(request.Username))
            throw new ParameterValidationException(nameof(request.Username));

        if (string.IsNullOrWhiteSpace(request.Email))
            throw new ParameterValidationException(nameof(request.Email));

        if (!request.Email.Contains('@'))
            throw new ParameterValidationException(nameof(request.Email));

        if (string.IsNullOrWhiteSpace(request.Password))
            throw new ParameterValidationException(nameof(request.Password));

        if (request.Password.Length < MinPasswordLength)
            throw new ParameterValidationException(nameof(request.Password));

        await ValidateRegisterRequestAsync(request);

        var user = new User(
            request.Email,
            PasswordHasher.HashPassword(request.Password),
            phoneNumber: null,
            GlobalConstants.DefaultLocale,
            Roles.User,
            request.Name,
            request.Surname)
        {
            Username = request.Username
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        await SendVerificationEmailAsync(user);

        return new TokenResponse { EmailConfirmationRequired = true };
    }

    /// <summary>
    /// Best-effort: a broken/unreachable SMTP server should never fail the request that got a user
    /// this far - it just means they have to ask for the link again via
    /// <see cref="ResendVerificationEmailAsync"/> instead of a successful registration turning into a
    /// 500.
    /// </summary>
    private async Task SendVerificationEmailAsync(User user)
    {
        try
        {
            var rawToken = GenerateSecureToken();

            _context.EmailVerificationTokens.Add(new EmailVerificationToken
            {
                UserId = user.Id,
                TokenHash = HashToken(rawToken),
                ExpiresAt = DateTime.UtcNow.AddMinutes(EmailVerificationTokenExpiresInMinutes),
            });

            await _context.SaveChangesAsync();

            var verificationLink = $"{_emailSettings.FrontendBaseUrl.TrimEnd('/')}/verify-email?token={Uri.EscapeDataString(rawToken)}";
            await _emailSender.SendVerificationEmailAsync(user.Email!, verificationLink);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to send verification email to user {UserId} - registration proceeds regardless", user.Id);
        }
    }

    public async Task ResetPasswordAsync(Guid userId, ResetPasswordRequest request, Guid currentUserId)
    {
        if (userId == Guid.Empty)
            throw new ParameterValidationException(nameof(userId));

        var currentUser = await _context.Users
            .FirstOrDefaultAsync(user => user.Id == currentUserId);

        if (currentUser is null)
            throw new UserNotFoundException(currentUserId);

        var targetUser = await _context.Users
            .FirstOrDefaultAsync(user => user.Id == userId);

        if (targetUser is null)
            throw new UserNotFoundException(userId);

        if (string.IsNullOrWhiteSpace(request.NewPassword))
            throw new ParameterValidationException(nameof(request.NewPassword));

        if (request.NewPassword.Length < MinPasswordLength)
            throw new ParameterValidationException(nameof(request.NewPassword));

        ValidateResetPermission(currentUser, targetUser);

        targetUser.Password = PasswordHasher.HashPassword(request.NewPassword!);

        await _context.SaveChangesAsync();
        await LogoutAllAsync(targetUser.Id);
    }

    private static void ValidateResetPermission(User currentUser, User targetUser)
    {
        if (currentUser.Role == Roles.Admin)
            return;

        throw new AccessDeniedException();
    }

    public async Task<TokenResponse> RefreshAsync(RefreshRequest request)
    {
        var accessPrincipal = GetPrincipalFromToken(request.AccessToken!);
        var refreshPrincipal = GetPrincipalFromToken(request.RefreshToken!);

        if (accessPrincipal is null || refreshPrincipal is null)
            throw new UnauthorizedAccessException();

        var accessSub = accessPrincipal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
                     ?? accessPrincipal.FindFirst("sub")?.Value
                     ?? accessPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        var refreshSub = refreshPrincipal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
                      ?? refreshPrincipal.FindFirst("sub")?.Value
                      ?? refreshPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (string.IsNullOrWhiteSpace(accessSub) ||
            string.IsNullOrWhiteSpace(refreshSub) ||
            !string.Equals(accessSub, refreshSub, StringComparison.Ordinal))
        {
            throw new UnauthorizedAccessException();
        }

        var sidClaim = refreshPrincipal.FindFirst(JwtRegisteredClaimNames.Sid)?.Value;
        if (!Guid.TryParse(sidClaim, out var sessionId))
            throw new UnauthorizedAccessException();

        var session = await _context.Sessions
            .FirstOrDefaultAsync(session => session.Id == sessionId);

        if (session is null || session.Expires < DateTime.UtcNow)
            throw new UnauthorizedAccessException();

        var refreshJti = refreshPrincipal.FindFirst(JwtRegisteredClaimNames.Jti)?.Value;
        if (!Guid.TryParse(refreshJti, out var refreshTokenId))
            throw new UnauthorizedAccessException();

        if (refreshTokenId != session.RefreshTokenId)
        {
            _logger.LogWarning("Refresh token reuse detected for session {SessionId} (user {UserId}) - session revoked",
                sessionId, session.UserId);
            await _context.Sessions.Where(s => s.Id == sessionId).ExecuteDeleteAsync();
            throw new UnauthorizedAccessException();
        }

        var user = await _context.Users
            .FirstOrDefaultAsync(user => user.Id == session.UserId);

        if (user is null || user.Disabled.HasValue)
            throw new UnauthorizedAccessException();

        session.AccessTokenId = Guid.NewGuid();
        session.RefreshTokenId = Guid.NewGuid();
        session.Refreshed = DateTime.UtcNow;

        // Only a "remembered" session keeps rolling its expiry forward on every refresh; a
        // non-persistent one hard-expires within NonPersistentSessionExpiresInHours of login
        // regardless of activity.
        if (session.IsPersistent)
            session.Expires = DateTime.UtcNow.AddDays(_settings.RefreshTokenExpiresInDays);

        await _context.SaveChangesAsync();

        return CreateSessionTokens(user, session);
    }

    public async Task LogoutAllAsync(Guid userId)
    {
        await _context.Sessions
            .Where(session => session.UserId == userId)
            .ExecuteDeleteAsync();
    }

    public async Task LogoutOtherSessionsAsync(Guid userId, Guid exceptSessionId)
    {
        await _context.Sessions
            .Where(session => session.UserId == userId && session.Id != exceptSessionId)
            .ExecuteDeleteAsync();
    }

    public async Task ChangePasswordAsync(Guid userId, Guid currentSessionId, ChangePasswordRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.CurrentPassword))
            throw new ParameterValidationException(nameof(request.CurrentPassword));

        if (string.IsNullOrWhiteSpace(request.NewPassword))
            throw new ParameterValidationException(nameof(request.NewPassword));

        if (request.NewPassword.Length < MinPasswordLength)
            throw new ParameterValidationException(nameof(request.NewPassword));

        var user = await _context.Users
            .FirstOrDefaultAsync(user => user.Id == userId);

        if (user is null || string.IsNullOrWhiteSpace(user.Password))
            throw new UserNotFoundException(userId);

        if (!PasswordHasher.VerifyHashedPassword(user.Password, request.CurrentPassword!))
            throw new InvalidCurrentPasswordException();

        user.Password = PasswordHasher.HashPassword(request.NewPassword!);

        await _context.SaveChangesAsync();
        await LogoutOtherSessionsAsync(userId, currentSessionId);
    }

    public async Task ForgotPasswordAsync(ForgotPasswordRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email))
            throw new ParameterValidationException(nameof(request.Email));

        var user = await _context.Users
            .FirstOrDefaultAsync(user => user.Email == request.Email);

        // Same response whether the account exists, is disabled, or the email is unregistered -
        // avoids leaking which emails are registered (user enumeration).
        if (user is null || user.Disabled.HasValue)
            return;

        await _context.PasswordResetTokens
            .Where(token => token.UserId == user.Id)
            .ExecuteDeleteAsync();

        var rawToken = GenerateSecureToken();

        _context.PasswordResetTokens.Add(new PasswordResetToken
        {
            UserId = user.Id,
            TokenHash = HashToken(rawToken),
            ExpiresAt = DateTime.UtcNow.AddMinutes(PasswordResetTokenExpiresInMinutes),
        });

        await _context.SaveChangesAsync();

        var resetLink = $"{_emailSettings.FrontendBaseUrl.TrimEnd('/')}/reset-password?token={Uri.EscapeDataString(rawToken)}";
        await _emailSender.SendPasswordResetEmailAsync(user.Email!, resetLink);
    }

    public async Task ConfirmPasswordResetAsync(ConfirmPasswordResetRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Token))
            throw new ParameterValidationException(nameof(request.Token));

        if (string.IsNullOrWhiteSpace(request.NewPassword))
            throw new ParameterValidationException(nameof(request.NewPassword));

        if (request.NewPassword.Length < MinPasswordLength)
            throw new ParameterValidationException(nameof(request.NewPassword));

        var tokenHash = HashToken(request.Token);

        var resetToken = await _context.PasswordResetTokens
            .FirstOrDefaultAsync(token => token.TokenHash == tokenHash);

        if (resetToken is null || resetToken.Used || resetToken.ExpiresAt < DateTime.UtcNow)
            throw new UnauthorizedAccessException();

        var user = await _context.Users
            .FirstOrDefaultAsync(user => user.Id == resetToken.UserId);

        if (user is null || user.Disabled.HasValue)
            throw new UnauthorizedAccessException();

        user.Password = PasswordHasher.HashPassword(request.NewPassword!);
        resetToken.Used = true;

        await _context.SaveChangesAsync();
        await LogoutAllAsync(user.Id);
    }

    public async Task ResendVerificationEmailAsync(ResendVerificationEmailRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email))
            throw new ParameterValidationException(nameof(request.Email));

        var user = await _context.Users
            .FirstOrDefaultAsync(user => user.Email == request.Email);

        // Same non-committal response whether the account doesn't exist, is disabled, or is
        // already verified - avoids leaking account state to an anonymous caller (user enumeration),
        // matching ForgotPasswordAsync's pattern above.
        if (user is null || user.Disabled.HasValue || user.EmailConfirmed)
            return;

        await _context.EmailVerificationTokens
            .Where(token => token.UserId == user.Id && !token.Used)
            .ExecuteDeleteAsync();

        await SendVerificationEmailAsync(user);
    }

    public async Task ConfirmEmailAsync(ConfirmEmailRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Token))
            throw new ParameterValidationException(nameof(request.Token));

        var tokenHash = HashToken(request.Token);

        var verificationToken = await _context.EmailVerificationTokens
            .FirstOrDefaultAsync(token => token.TokenHash == tokenHash);

        if (verificationToken is null || verificationToken.Used || verificationToken.ExpiresAt < DateTime.UtcNow)
            throw new UnauthorizedAccessException();

        var user = await _context.Users
            .FirstOrDefaultAsync(user => user.Id == verificationToken.UserId);

        if (user is null || user.Disabled.HasValue)
            throw new UnauthorizedAccessException();

        user.EmailConfirmed = true;
        verificationToken.Used = true;

        await _context.SaveChangesAsync();
    }

    private static string GenerateSecureToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(32);
        return Convert.ToBase64String(bytes).Replace('+', '-').Replace('/', '_').TrimEnd('=');
    }

    private static string HashToken(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToHexString(bytes);
    }

    private async Task ValidateRegisterRequestAsync(RegisterRequestBase request)
    {
        var emailExists = await _context.Users.AnyAsync(user => user.Email == request.Email);

        if (emailExists)
            throw new UserAlreadyExistsException(request.Email);

        var usernameExists = await _context.Users
            .AnyAsync(user => user.Username != null && user.Username.ToLower() == request.Username.ToLower());

        if (usernameExists)
            throw new UsernameAlreadyTakenException(request.Username);
    }

    /// <summary>
    /// Unauthenticated live-availability check for the registration form. Malformed input is reported
    /// as unavailable without touching the database - a username that can never be registered (per
    /// <see cref="UsernamePolicy"/>) is trivially "not available" regardless of what's taken. Reuses
    /// <see cref="ValidateRegisterRequestAsync"/>'s exact case-insensitive uniqueness query, kept as its
    /// own copy here rather than factored out, so this read-only check can never affect registration's
    /// own validation path.
    /// </summary>
    public async Task<UsernameAvailabilityResponse> CheckUsernameAvailableAsync(string? username)
    {
        if (!UsernamePolicy.IsValid(username))
            return new UsernameAvailabilityResponse { Available = false };

        var usernameExists = await _context.Users
            .AnyAsync(user => user.Username != null && user.Username.ToLower() == username!.ToLower());

        return new UsernameAvailabilityResponse { Available = !usernameExists };
    }

    /// <summary>
    /// True when a login attempt for this account must be rejected. A plain admin-disabled account
    /// (<see cref="User.Disabled"/> set, <see cref="User.DeletionRequestedAt"/> null) is always
    /// rejected. An account mid self-service deletion (both set) is deliberately let through here -
    /// logging back in during the grace period is what cancels the deletion, via
    /// <see cref="CreateNewSessionAsync"/> below. Internal so <c>QrLoginService</c>'s own
    /// session-minting poll applies the exact same carve-out.
    /// </summary>
    internal static bool IsBlockedFromLoggingIn(User user) =>
        user.Disabled.HasValue && user.DeletionRequestedAt is null;

    /// <summary>Internal so QrLoginService can mint a session once a cross-device sign-in is approved.</summary>
    internal async Task<TokenResponse> CreateNewSessionAsync(User user, bool rememberMe)
    {
        // A successful login is what cancels a pending self-service deletion - see
        // IsBlockedFromLoggingIn, which is what let this account's login attempt reach here at all
        // despite Disabled being set.
        if (user.DeletionRequestedAt is not null)
        {
            user.Disabled = null;
            user.DeletionRequestedAt = null;
        }

        var (userAgent, ipAddress, deviceLabel, browser, os) = ResolveClientInfo();

        // A fresh login from the same browser/device (same UA + IP) supersedes whatever session
        // that device already held - without this, a device that logs in repeatedly without ever
        // hitting the explicit logout button (closing the tab, clearing storage, reinstalling the
        // app) piles up one still-valid Session row per login, all shown as separate "active
        // sessions" for what is really one device. Requiring both signals together (rather than UA
        // alone) keeps this from misfiring across two genuinely different devices that merely share
        // a common browser/OS string.
        if (!string.IsNullOrWhiteSpace(userAgent) && !string.IsNullOrWhiteSpace(ipAddress))
        {
            await _context.Sessions
                .Where(existing => existing.UserId == user.Id
                    && existing.UserAgent == userAgent
                    && existing.IpAddress == ipAddress)
                .ExecuteDeleteAsync();
        }

        var session = new Session
        {
            UserId = user.Id,
            AccessTokenId = Guid.NewGuid(),
            RefreshTokenId = Guid.NewGuid(),
            IsPersistent = rememberMe,
            Expires = rememberMe
                ? DateTime.UtcNow.AddDays(_settings.RefreshTokenExpiresInDays)
                : DateTime.UtcNow.AddHours(_settings.NonPersistentSessionExpiresInHours),
            UserAgent = userAgent,
            IpAddress = ipAddress,
            DeviceLabel = deviceLabel,
            Browser = browser,
            OS = os
        };

        _context.Sessions.Add(session);
        await _context.SaveChangesAsync();

        return CreateSessionTokens(user, session);
    }

    /// <summary>Internal so QrLoginService can record which device asked to sign in.</summary>
    internal (string? UserAgent, string? IpAddress, string? DeviceLabel, string? Browser, string? OS) ResolveClientInfo()
    {
        var httpContext = _httpContextAccessor.HttpContext;

        var userAgent = httpContext?.Request.Headers.UserAgent.ToString();
        var ipAddress = httpContext?.Connection.RemoteIpAddress?.ToString();

        if (string.IsNullOrWhiteSpace(userAgent))
            return (userAgent, ipAddress, null, null, null);

        var clientInfo = Parser.GetDefault().Parse(userAgent);
        var browser = clientInfo.UA.Family;
        var os = clientInfo.OS.Family;
        var deviceLabel = $"{browser} on {os}".Trim();

        return (userAgent, ipAddress, deviceLabel, browser, os);
    }

    private TokenResponse CreateSessionTokens(User user, Session session)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_settings.SigningKey!));

        var accessClaims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(ClaimTypes.Role, user.Role.ToString()),
            new Claim("role", user.Role.ToString()),
            new Claim(JwtRegisteredClaimNames.Sid, session.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Jti, session.AccessTokenId.ToString()),
        };

        var refreshClaims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Sid, session.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Jti, session.RefreshTokenId.ToString()),
        };

        var accessTokenExpires = DateTime.UtcNow.AddMinutes(_settings.AccessTokenExpiresInMinutes);

        var accessJwt = new JwtSecurityToken(
            issuer: _settings.Issuer,
            audience: _settings.Audience,
            claims: accessClaims,
            expires: accessTokenExpires,
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256)
        );

        var refreshJwt = new JwtSecurityToken(
            issuer: _settings.Issuer,
            audience: _settings.Audience,
            claims: refreshClaims,
            expires: session.Expires,
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256)
        );

        var handler = new JwtSecurityTokenHandler();

        return new TokenResponse
        {
            AccessToken = handler.WriteToken(accessJwt),
            RefreshToken = handler.WriteToken(refreshJwt),
            AccessTokenExpires = accessTokenExpires,
            RefreshTokenExpires = session.Expires
        };
    }

    /// <summary>
    /// Validates a refresh token. Lifetime is deliberately not checked here - expiry for a refresh
    /// token is the <c>Session.Expires</c> column, which <see cref="RefreshAsync"/> checks itself.
    /// </summary>
    private ClaimsPrincipal? GetPrincipalFromToken(string token)
    {
        return GetPrincipalFromToken(token, _settings.Audience!, validateLifetime: false);
    }

    /// <summary>
    /// Validates a token minted for a non-session purpose (currently the two-factor interstitial).
    /// Lifetime <em>is</em> enforced: unlike a refresh token there is no database row bounding it, so
    /// the JWT's own expiry is the only thing that ends it.
    /// </summary>
    private ClaimsPrincipal? GetPrincipalFromToken(string token, string audience)
    {
        return GetPrincipalFromToken(token, audience, validateLifetime: true);
    }

    private ClaimsPrincipal? GetPrincipalFromToken(string token, string audience, bool validateLifetime)
    {
        var tokenHandler = new JwtSecurityTokenHandler();
        tokenHandler.InboundClaimTypeMap.Clear();

        var validationParams = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = validateLifetime,
            ClockSkew = TimeSpan.Zero,
            ValidateIssuerSigningKey = true,
            ValidIssuer = _settings.Issuer,
            ValidAudience = audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_settings.SigningKey!)),
            NameClaimType = JwtRegisteredClaimNames.Sub,
            RoleClaimType = "role"
        };

        try
        {
            return tokenHandler.ValidateToken(token, validationParams, out _);
        }
        catch
        {
            return null;
        }
    }
}