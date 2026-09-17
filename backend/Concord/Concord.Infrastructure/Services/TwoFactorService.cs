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

public class TwoFactorService(
    ApplicationDbContext context,
    IDataProtectionProvider dataProtectionProvider,
    ILogger<TwoFactorService> logger)
{
    private const string ProtectorPurpose = "TwoFactorSecret";

    private const int SecretBytes = 20;

    private const int RecoveryCodeCount = 10;

    private const int RecoveryCodeBytes = 5;

    private const int VerificationWindowSteps = 1;

    private const int TotpStepSeconds = 30;

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

        var secretBytes = RandomNumberGenerator.GetBytes(SecretBytes);
        var secret = Base32Encoding.ToString(secretBytes).TrimEnd('=');

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

        if (normalized.Length == 6 && normalized.All(char.IsDigit) && TryConsumeTotp(user, normalized))
            return true;

        return await TryConsumeRecoveryCodeAsync(user.Id, normalized);
    }

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

        var match = candidates.FirstOrDefault(entry =>
            !string.IsNullOrWhiteSpace(entry.CodeHash) &&
            PasswordHasher.VerifyHashedPassword(entry.CodeHash, code));

        if (match is null)
            return false;

        match.UsedAt = DateTime.UtcNow;

        _logger.LogInformation("Recovery code redeemed for user {UserId}", userId);

        return true;
    }

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
        const string issuer = "Concord";

        var account = string.IsNullOrWhiteSpace(user.Email) ? user.Username ?? user.Id.ToString() : user.Email;
        var label = Uri.EscapeDataString($"{issuer}:{account}");

        return $"otpauth://totp/{label}?secret={secret}&issuer={Uri.EscapeDataString(issuer)}&algorithm=SHA1&digits=6&period={TotpStepSeconds}";
    }

    private static string BuildQrCodeSvgDataUri(string otpAuthUri)
    {
        using var generator = new QRCodeGenerator();
        using var data = generator.CreateQrCode(otpAuthUri, QRCodeGenerator.ECCLevel.Q);

        var svg = new SvgQRCode(data).GetGraphic(5);

        return $"data:image/svg+xml;base64,{Convert.ToBase64String(Encoding.UTF8.GetBytes(svg))}";
    }

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
