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

/// <summary>
/// Cross-device sign-in by QR code (P3), modelled on the OAuth device authorization grant.
///
/// The browser has no credentials, so it cannot hold an authenticated connection - it starts a
/// request, shows the code, and polls. An already-signed-in device approves, and the *next* poll
/// exchanges the approval for a real session.
///
/// The security of the flow rests on three things:
///   <list type="number">
///     <item>The QR carries only the short user code, which grants nothing on its own; the
///     high-entropy polling token never leaves the browser that started the request.</item>
///     <item>Approval requires an authenticated caller, so the code alone cannot mint a session.</item>
///     <item>Approvals are single-use and short-lived, and the approver is shown the requesting
///     device rather than being asked to trust a bare code.</item>
///   </list>
/// </summary>
public class QrLoginService(
    ApplicationDbContext context,
    AuthenticationService authenticationService,
    IOptions<EmailSettings> emailOptions,
    ILogger<QrLoginService> logger)
{
    /// <summary>
    /// Short enough that an abandoned code on a shared screen stops being useful quickly; long
    /// enough to unlock a phone and approve.
    /// </summary>
    private const int SessionExpiresInMinutes = 2;

    /// <summary>Excludes I/O/0/1 - the code is read off one screen and typed into another.</summary>
    private const string UserCodeAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

    private const int UserCodeLength = 8;

    /// <summary>32 bytes of entropy for the value that actually collects the session.</summary>
    private const int PollingTokenBytes = 32;

    private readonly ApplicationDbContext _context = context;
    private readonly AuthenticationService _authenticationService = authenticationService;
    private readonly EmailSettings _emailSettings = emailOptions.Value;
    private readonly ILogger<QrLoginService> _logger = logger;

    /// <summary>
    /// Starts a request from an unauthenticated browser. Records that browser's device details for
    /// the approver to inspect.
    /// </summary>
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

    /// <summary>
    /// The waiting browser's poll. On the first call after approval this mints the session, returns
    /// the tokens, and marks the request consumed - so a replayed poll gets nothing.
    /// </summary>
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

        // The approver could have been disabled between approving and this poll. An account mid
        // self-service deletion (DeletionRequestedAt set alongside Disabled) is let through, same as
        // the password-login paths in AuthenticationService - completing this sign-in cancels the
        // deletion, since CreateNewSessionAsync clears both fields once it mints the session below.
        if (user is null || AuthenticationService.IsBlockedFromLoggingIn(user))
            throw new UnauthorizedAccessException();

        // Claim the approval atomically, before any session is minted. Read-then-save would let two
        // concurrent polls both observe Approved and each walk away with a session; the WHERE clause
        // means exactly one update can match, and whoever loses sees zero rows affected.
        var claimed = await _context.QrLoginSessions
            .Where(entry => entry.Id == session.Id && entry.Status == QrLoginStatus.Approved)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(entry => entry.Status, QrLoginStatus.Consumed)
                .SetProperty(entry => entry.ConsumedAt, DateTime.UtcNow));

        if (claimed == 0)
            return new QrLoginStatusResponse { Status = QrLoginStatus.Consumed, Expired = false };

        // Not persistent: a session obtained by scanning a code on some other device should not
        // outlive the browser, the way an explicit "remember me" tick would.
        var tokens = await _authenticationService.CreateNewSessionAsync(user, rememberMe: false);

        _logger.LogInformation("QR sign-in completed for user {UserId} from {DeviceLabel}", user.Id, session.DeviceLabel);

        return new QrLoginStatusResponse
        {
            Status = QrLoginStatus.Consumed,
            Expired = false,
            Tokens = tokens
        };
    }

    /// <summary>
    /// Details of a pending request, for the approval screen. Requires an authenticated caller: the
    /// code alone must not reveal where a sign-in attempt is coming from.
    /// </summary>
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

    /// <summary>
    /// Resolves a code to a request that can still be acted on. Expired, already-decided, and
    /// unknown codes are all rejected here rather than at each call site.
    /// </summary>
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

    /// <summary>
    /// Uppercases and strips the separators a person may retype. The alphabet excludes the
    /// characters that get confused, so no further substitution is attempted - silently "correcting"
    /// a typo into a different valid code would be worse than rejecting it.
    /// </summary>
    private static string NormalizeUserCode(string userCode) =>
        userCode.Replace("-", string.Empty).Replace(" ", string.Empty).Trim().ToUpperInvariant();

    private async Task<string> GenerateUniqueUserCodeAsync()
    {
        // 32^8 is ~1.1e12; over a two-minute window a collision is vanishingly unlikely, but the
        // column is uniquely indexed so a clash must not become a 500.
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
