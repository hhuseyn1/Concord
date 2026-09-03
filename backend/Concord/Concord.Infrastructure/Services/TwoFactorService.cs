using System.Security.Cryptography;
using System.Text;
using Concord.Application.Models;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;

using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using OtpNet;
using QRCoder;

namespace Concord.Infrastructure.Services;

/// <summary>
/// TOTP second factor (P2, RFC 6238) plus single-use recovery codes.
///
/// Enrolment is two-phase on purpose: <see cref="StartSetupAsync"/> writes a secret but leaves
/// <c>TwoFactorEnabled</c> false, and only <see cref="EnableAsync"/> - which requires a code the
/// authenticator actually produced - flips it on. Someone who never finishes scanning is therefore
/// never locked out by a half-finished setup.
/// </summary>
public class TwoFactorService(
    ApplicationDbContext context,
    IDataProtectionProvider dataProtectionProvider,
    ILogger<TwoFactorService> logger)
{
    /// <summary>
    /// Purpose string scopes the protector so this key can never be reused to decrypt data protected
    /// under a different purpose elsewhere in the app, even though they'd share the same key ring.
    /// </summary>
    private const string ProtectorPurpose = "TwoFactorSecret";

    /// <summary>Secret size recommended by RFC 4226 for HMAC-SHA1.</summary>
    private const int SecretBytes = 20;

    private const int RecoveryCodeCount = 10;

    /// <summary>Bytes per recovery code; 5 bytes render as 8 base32 characters.</summary>
    private const int RecoveryCodeBytes = 5;

    /// <summary>
    /// Accepts the previous and next step as well as the current one, tolerating roughly +/-30s of
    /// clock drift between the phone and this server. Wider would meaningfully extend the window in
    /// which an observed code still works.
    /// </summary>
    private const int VerificationWindowSteps = 1;

    private const int TotpStepSeconds = 30;

    /// <summary>Base32 without padding, per the otpauth URI convention.</summary>
    private const string Base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

    private readonly ApplicationDbContext _context = context;
    private readonly IDataProtector _protector = dataProtectionProvider.CreateProtector(ProtectorPurpose);
    private readonly ILogger<TwoFactorService> _logger = logger;

    public async Task<TwoFactorStatusResponse> GetStatusAsync(Guid userId)
    {
        var user = await GetUserAsync(userId);

        var remaining = user.TwoFactorEnabled
            ? await _context.TwoFactorRecoveryCodes.CountAsync(code => code.UserId == userId && code.UsedAt == null)
            : 0;

        return new TwoFactorStatusResponse
        {
            Enabled = user.TwoFactorEnabled,
            EnabledAt = user.TwoFactorEnabledAt,
            SetupPending = !user.TwoFactorEnabled && !string.IsNullOrWhiteSpace(user.TwoFactorSecret),
            RemainingRecoveryCodes = remaining
        };
    }

    public async Task<TwoFactorSetupResponse> StartSetupAsync(Guid userId)
    {
        var user = await GetUserAsync(userId);

        if (user.TwoFactorEnabled)
            throw new TwoFactorAlreadyEnabledException();

        // A fresh secret every time setup is started: restarting after an abandoned attempt must
        // invalidate whatever the previous QR encoded, not resurrect it.
        var secretBytes = RandomNumberGenerator.GetBytes(SecretBytes);
        var secret = Base32Encoding.ToString(secretBytes).TrimEnd('=');

        // Encrypted at rest: only this protector (see ProtectorPurpose) can turn it back into the
        // base32 secret, and only TryConsumeTotp ever needs to.
        user.TwoFactorSecret = _protector.Protect(secret);

        await _context.SaveChangesAsync();

        var otpAuthUri = BuildOtpAuthUri(user, secret);

        return new TwoFactorSetupResponse
        {
            SecretKey = FormatSecretForDisplay(secret),
            OtpAuthUri = otpAuthUri,
            QrCodeSvg = BuildQrCodeSvgDataUri(otpAuthUri)
        };
    }

    public async Task<RecoveryCodesResponse> EnableAsync(Guid userId, string? code)
    {
        var user = await GetUserAsync(userId);

        if (user.TwoFactorEnabled)
            throw new TwoFactorAlreadyEnabledException();

        if (string.IsNullOrWhiteSpace(user.TwoFactorSecret))
            throw new TwoFactorSetupNotStartedException();

        if (!TryConsumeTotp(user, code))
            throw new InvalidTwoFactorCodeException();

        user.TwoFactorEnabled = true;
        user.TwoFactorEnabledAt = DateTime.UtcNow;

        var codes = await ReplaceRecoveryCodesAsync(user.Id);

        await _context.SaveChangesAsync();

        _logger.LogInformation("Two-factor authentication enabled for user {UserId}", userId);

        return new RecoveryCodesResponse { Codes = codes };
    }

    public async Task DisableAsync(Guid userId, DisableTwoFactorRequest request)
    {
        var user = await GetUserAsync(userId);

        if (!user.TwoFactorEnabled)
            throw new TwoFactorNotEnabledException();

        // Password *and* a second factor: turning the second factor off is exactly the action an
        // attacker on a hijacked session would want, so it is gated at least as hard as using it.
        if (string.IsNullOrWhiteSpace(request.Password) ||
            string.IsNullOrWhiteSpace(user.Password) ||
            !PasswordHasher.VerifyHashedPassword(user.Password, request.Password))
            throw new InvalidCurrentPasswordException();

        if (!await VerifyCodeOrRecoveryAsync(user, request.Code))
            throw new InvalidTwoFactorCodeException();

        user.TwoFactorEnabled = false;
        user.TwoFactorSecret = null;
        user.TwoFactorEnabledAt = null;
        user.TwoFactorLastUsedStep = null;

        var codes = await _context.TwoFactorRecoveryCodes.Where(entry => entry.UserId == userId).ToListAsync();
        _context.TwoFactorRecoveryCodes.RemoveRange(codes);

        await _context.SaveChangesAsync();

        _logger.LogWarning("Two-factor authentication disabled for user {UserId}", userId);
    }

    public async Task<RecoveryCodesResponse> RegenerateRecoveryCodesAsync(Guid userId, string? password)
    {
        var user = await GetUserAsync(userId);

        if (!user.TwoFactorEnabled)
            throw new TwoFactorNotEnabledException();

        if (string.IsNullOrWhiteSpace(password) ||
            string.IsNullOrWhiteSpace(user.Password) ||
            !PasswordHasher.VerifyHashedPassword(user.Password, password))
            throw new InvalidCurrentPasswordException();

        var codes = await ReplaceRecoveryCodesAsync(userId);

        await _context.SaveChangesAsync();

        _logger.LogInformation("Recovery codes regenerated for user {UserId}", userId);

        return new RecoveryCodesResponse { Codes = codes };
    }

    /// <summary>
    /// Validates a login's second factor: a current TOTP code, or an unused recovery code. Called by
    /// <see cref="AuthenticationService"/> after the password step, and by
    /// <see cref="DisableAsync"/>. Persists on success, since both paths consume something.
    /// </summary>
    public async Task<bool> VerifyForLoginAsync(User user, string? code)
    {
        var verified = await VerifyCodeOrRecoveryAsync(user, code);

        if (verified)
            await _context.SaveChangesAsync();

        return verified;
    }

    private async Task<bool> VerifyCodeOrRecoveryAsync(User user, string? code)
    {
        if (string.IsNullOrWhiteSpace(code))
            return false;

        var normalized = code.Replace(" ", string.Empty).Replace("-", string.Empty).Trim();

        // Six digits is a TOTP code; anything else can only be a recovery code. Trying TOTP first
        // keeps the common path to zero database reads beyond the user row already in hand.
        if (normalized.Length == 6 && normalized.All(char.IsDigit) && TryConsumeTotp(user, normalized))
            return true;

        return await TryConsumeRecoveryCodeAsync(user.Id, normalized);
    }

    /// <summary>
    /// Verifies a TOTP code and burns its time step. Returns false for a code from a step at or
    /// before the last one this account used, which is what stops the same six digits being replayed
    /// inside their validity window.
    /// </summary>
    private bool TryConsumeTotp(User user, string? code)
    {
        if (string.IsNullOrWhiteSpace(code) || string.IsNullOrWhiteSpace(user.TwoFactorSecret))
            return false;

        byte[] secretBytes;

        try
        {
            var decryptedSecret = _protector.Unprotect(user.TwoFactorSecret);
            secretBytes = Base32Encoding.ToBytes(decryptedSecret);
        }
        catch (Exception ex)
        {
            // Also hit by a secret written before this column carried encrypted data - it cannot be
            // unprotected by this (or any) key, so that account's existing enrolment is effectively
            // dead and needs to be redone. No migration path exists for it - see the P2 remediation
            // notes.
            _logger.LogError(ex, "Stored TOTP secret for user {UserId} could not be decrypted/decoded", user.Id);
            return false;
        }

        var totp = new Totp(secretBytes, step: TotpStepSeconds, mode: OtpHashMode.Sha1, totpSize: 6);

        var verified = totp.VerifyTotp(
            code.Trim(),
            out var matchedStep,
            new VerificationWindow(previous: VerificationWindowSteps, future: VerificationWindowSteps));

        if (!verified)
            return false;

        if (user.TwoFactorLastUsedStep is { } lastStep && matchedStep <= lastStep)
        {
            _logger.LogWarning("Replayed TOTP code rejected for user {UserId} (step {Step})", user.Id, matchedStep);
            return false;
        }

        user.TwoFactorLastUsedStep = matchedStep;

        return true;
    }

    private async Task<bool> TryConsumeRecoveryCodeAsync(Guid userId, string code)
    {
        var candidates = await _context.TwoFactorRecoveryCodes
            .Where(entry => entry.UserId == userId && entry.UsedAt == null)
            .ToListAsync();

        // Salted per row, so there is no lookup key - every unused code has to be compared. Ten of
        // them is a fixed, tiny cost, and it keeps the codes as unguessable as a password hash.
        var match = candidates.FirstOrDefault(entry =>
            !string.IsNullOrWhiteSpace(entry.CodeHash) &&
            PasswordHasher.VerifyHashedPassword(entry.CodeHash, code));

        if (match is null)
            return false;

        match.UsedAt = DateTime.UtcNow;

        _logger.LogInformation("Recovery code redeemed for user {UserId}", userId);

        return true;
    }

    /// <summary>Replaces every existing code, spent or not - regenerating must invalidate the old sheet.</summary>
    private async Task<List<string>> ReplaceRecoveryCodesAsync(Guid userId)
    {
        var existing = await _context.TwoFactorRecoveryCodes.Where(entry => entry.UserId == userId).ToListAsync();
        _context.TwoFactorRecoveryCodes.RemoveRange(existing);

        var codes = new List<string>(RecoveryCodeCount);

        for (var index = 0; index < RecoveryCodeCount; index++)
        {
            var code = GenerateRecoveryCode();
            codes.Add(code);

            _context.TwoFactorRecoveryCodes.Add(new TwoFactorRecoveryCode
            {
                UserId = userId,
                CodeHash = PasswordHasher.HashPassword(code)
            });
        }

        return codes;
    }

    private static string GenerateRecoveryCode()
    {
        var bytes = RandomNumberGenerator.GetBytes(RecoveryCodeBytes);
        var builder = new StringBuilder(9);

        // 5 bytes -> 8 base32 chars, hyphenated in the middle purely so they are easier to read back.
        var value = 0L;
        foreach (var b in bytes)
            value = (value << 8) | b;

        for (var index = 7; index >= 0; index--)
        {
            var chunk = (int)((value >> (index * 5)) & 0x1F);
            builder.Append(Base32Alphabet[chunk]);
        }

        return builder.ToString().Insert(4, "-");
    }

    private string BuildOtpAuthUri(User user, string secret)
    {
        // The issuer appears as the account's heading in the authenticator app, so it should read as
        // the product name rather than a hostname.
        const string issuer = "Concord";

        var account = string.IsNullOrWhiteSpace(user.Email) ? user.Username ?? user.Id.ToString() : user.Email;
        var label = Uri.EscapeDataString($"{issuer}:{account}");

        return $"otpauth://totp/{label}?secret={secret}&issuer={Uri.EscapeDataString(issuer)}&algorithm=SHA1&digits=6&period={TotpStepSeconds}";
    }

    /// <summary>
    /// Renders the URI as an SVG data URI. Done server-side so the web client needs no QR library,
    /// and so the same endpoint can serve any future client unchanged.
    /// </summary>
    private static string BuildQrCodeSvgDataUri(string otpAuthUri)
    {
        using var generator = new QRCodeGenerator();
        using var data = generator.CreateQrCode(otpAuthUri, QRCodeGenerator.ECCLevel.Q);

        var svg = new SvgQRCode(data).GetGraphic(5);

        return $"data:image/svg+xml;base64,{Convert.ToBase64String(Encoding.UTF8.GetBytes(svg))}";
    }

    /// <summary>Groups the secret into fours so it can be typed accurately when a QR cannot be scanned.</summary>
    private static string FormatSecretForDisplay(string secret)
    {
        return string.Join(' ', Enumerable
            .Range(0, (secret.Length + 3) / 4)
            .Select(index => secret.Substring(index * 4, Math.Min(4, secret.Length - (index * 4)))));
    }

    private async Task<User> GetUserAsync(Guid userId)
    {
        return await _context.Users.FirstOrDefaultAsync(user => user.Id == userId)
            ?? throw new UserNotFoundException(userId);
    }
}
