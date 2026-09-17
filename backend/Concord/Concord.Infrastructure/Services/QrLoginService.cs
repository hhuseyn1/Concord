using System.Security.Cryptography;
using System.Text;
using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Settings;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using QRCoder;

namespace Concord.Infrastructure.Services;

public class QrLoginService(
    ApplicationDbContext context,
    AuthenticationService authenticationService,
    IOptions<EmailSettings> emailOptions,
    ILogger<QrLoginService> logger)
{
    private const int SessionExpiresInMinutes = 2;

    private const string UserCodeAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

    private const int UserCodeLength = 8;

    private const int PollingTokenBytes = 32;

    private readonly ApplicationDbContext _context = context;
    private readonly AuthenticationService _authenticationService = authenticationService;
    private readonly EmailSettings _emailSettings = emailOptions.Value;
    private readonly ILogger<QrLoginService> _logger = logger;

    public async Task<QrLoginStartResponse> StartAsync()
    {
        var (userAgent, ipAddress, deviceLabel, browser, os) = _authenticationService.ResolveClientInfo();

        var pollingToken = Convert.ToHexString(RandomNumberGenerator.GetBytes(PollingTokenBytes));
        var userCode = await GenerateUniqueUserCodeAsync();

        var session = new QrLoginSession
        {
            UserCode = userCode,
            PollingTokenHash = HashToken(pollingToken),
            Status = QrLoginStatus.Pending,
            ExpiresAtUtc = DateTime.UtcNow.AddMinutes(SessionExpiresInMinutes),
            UserAgent = userAgent,
            IpAddress = ipAddress,
            DeviceLabel = deviceLabel,
            Browser = browser,
            OS = os
        };

        _context.QrLoginSessions.Add(session);

        await _context.SaveChangesAsync();

        var approvalUrl = $"{_emailSettings.FrontendBaseUrl.TrimEnd('/')}/link?code={Uri.EscapeDataString(userCode)}";

        return new QrLoginStartResponse
        {
            UserCode = userCode,
            PollingToken = pollingToken,
            ApprovalUrl = approvalUrl,
            QrCodeSvg = BuildQrCodeSvgDataUri(approvalUrl),
            ExpiresAtUtc = session.ExpiresAtUtc
        };
    }

    public async Task<QrLoginStatusResponse> GetStatusAsync(string? pollingToken)
    {
        if (string.IsNullOrWhiteSpace(pollingToken))
            throw new ParameterValidationException(nameof(pollingToken));

        var hash = HashToken(pollingToken);

        var session = await _context.QrLoginSessions.FirstOrDefaultAsync(entry => entry.PollingTokenHash == hash)
            ?? throw new QrLoginSessionNotFoundException();

        if (session.ExpiresAtUtc <= DateTime.UtcNow)
            return new QrLoginStatusResponse { Status = session.Status, Expired = true };

        if (session.Status != QrLoginStatus.Approved)
            return new QrLoginStatusResponse { Status = session.Status, Expired = false };

        var user = await _context.Users.FirstOrDefaultAsync(entry => entry.Id == session.ApprovedByUserId);

        if (user is null || AuthenticationService.IsBlockedFromLoggingIn(user))
            throw new UnauthorizedAccessException();

        var claimed = await _context.QrLoginSessions
            .Where(entry => entry.Id == session.Id && entry.Status == QrLoginStatus.Approved)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(entry => entry.Status, QrLoginStatus.Consumed)
                .SetProperty(entry => entry.ConsumedAt, DateTime.UtcNow));

        if (claimed == 0)
            return new QrLoginStatusResponse { Status = QrLoginStatus.Consumed, Expired = false };

        var tokens = await _authenticationService.CreateNewSessionAsync(user, rememberMe: false);

        _logger.LogInformation("QR sign-in completed for user {UserId} from {DeviceLabel}", user.Id, session.DeviceLabel);

        return new QrLoginStatusResponse
        {
            Status = QrLoginStatus.Consumed,
            Expired = false,
            Tokens = tokens
        };
    }

    public async Task<QrLoginRequestInfoResponse> GetRequestInfoAsync(string? userCode)
    {
        var session = await GetPendingSessionAsync(userCode);

        return new QrLoginRequestInfoResponse
        {
            UserCode = session.UserCode,
            DeviceLabel = session.DeviceLabel,
            Browser = session.Browser,
            OS = session.OS,
            IpAddress = session.IpAddress,
            RequestedAt = session.Created,
            ExpiresAtUtc = session.ExpiresAtUtc
        };
    }

    public async Task ApproveAsync(Guid currentUserId, string? userCode)
    {
        var session = await GetPendingSessionAsync(userCode);

        session.Status = QrLoginStatus.Approved;
        session.ApprovedByUserId = currentUserId;

        await _context.SaveChangesAsync();

        _logger.LogInformation("QR sign-in {UserCode} approved by user {UserId}", session.UserCode, currentUserId);
    }

    public async Task DenyAsync(Guid currentUserId, string? userCode)
    {
        var session = await GetPendingSessionAsync(userCode);

        session.Status = QrLoginStatus.Denied;

        await _context.SaveChangesAsync();

        _logger.LogWarning("QR sign-in {UserCode} denied by user {UserId}", session.UserCode, currentUserId);
    }

    private async Task<QrLoginSession> GetPendingSessionAsync(string? userCode)
    {
        if (string.IsNullOrWhiteSpace(userCode))
            throw new ParameterValidationException(nameof(userCode));

        var normalized = NormalizeUserCode(userCode);

        var session = await _context.QrLoginSessions.FirstOrDefaultAsync(entry => entry.UserCode == normalized)
            ?? throw new QrLoginSessionNotFoundException();

        if (session.ExpiresAtUtc <= DateTime.UtcNow)
            throw new QrLoginSessionNotFoundException();

        if (session.Status != QrLoginStatus.Pending)
            throw new QrLoginNotApprovedException("That sign-in request has already been handled.");

        return session;
    }

    private static string NormalizeUserCode(string userCode) =>
        userCode.Replace("-", string.Empty).Replace(" ", string.Empty).Trim().ToUpperInvariant();

    private async Task<string> GenerateUniqueUserCodeAsync()
    {
        for (var attempt = 0; attempt < 5; attempt++)
        {
            var candidate = RandomNumberGenerator.GetString(UserCodeAlphabet, UserCodeLength);

            if (!await _context.QrLoginSessions.AnyAsync(entry => entry.UserCode == candidate))
                return candidate;
        }

        throw new InvalidOperationException("Could not allocate a unique QR sign-in code.");
    }

    private static string HashToken(string token)
    {
        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));
    }

    private static string BuildQrCodeSvgDataUri(string payload)
    {
        using var generator = new QRCodeGenerator();
        using var data = generator.CreateQrCode(payload, QRCodeGenerator.ECCLevel.Q);

        var svg = new SvgQRCode(data).GetGraphic(5);

        return $"data:image/svg+xml;base64,{Convert.ToBase64String(Encoding.UTF8.GetBytes(svg))}";
    }
}
