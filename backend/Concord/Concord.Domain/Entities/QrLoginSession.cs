using Concord.Application.Enums;

namespace Concord.Domain.Entities;

/// <summary>
/// A pending cross-device sign-in (P3), in the shape of the OAuth device authorization grant: a
/// browser with no credentials displays a code, and an already-signed-in device approves it.
///
/// Two separate secrets, deliberately:
///   <list type="bullet">
///     <item><see cref="UserCode"/> is short and shown on screen (and encoded in the QR). It only
///     identifies the request to an <em>authenticated</em> approver - on its own it grants nothing.</item>
///     <item><see cref="PollingTokenHash"/> is a high-entropy secret held only by the waiting
///     browser, and is the sole way to collect the resulting session.</item>
///   </list>
/// That split is what stops someone who photographs the QR from also collecting the session: they
/// can see the code, but they cannot poll for its result.
/// </summary>
public class QrLoginSession : BaseEntity
{
    public Guid Id { get; set; }

    /// <summary>Short, human-readable, and case-normalised - typed by a person, not a machine.</summary>
    public string? UserCode { get; set; }

    /// <summary>SHA-256 of the browser's polling secret; the raw value is never stored.</summary>
    public string? PollingTokenHash { get; set; }

    public QrLoginStatus Status { get; set; }

    public Guid? ApprovedByUserId { get; set; }

    public DateTime ExpiresAtUtc { get; set; }

    public DateTime? ConsumedAt { get; set; }

    /// <summary>
    /// Details of the device that asked to sign in, captured at request time and shown to the
    /// approver. Approving blind is the whole risk of this flow - a phishing page can display a QR
    /// it did not generate - so the approver is told what they are actually authorising.
    /// </summary>
    public string? UserAgent { get; set; }
    public string? IpAddress { get; set; }
    public string? DeviceLabel { get; set; }
    public string? Browser { get; set; }
    public string? OS { get; set; }
}
