using Concord.Application.Enums;

namespace Concord.Domain.Entities;

public class QrLoginSession : BaseEntity
{
    public Guid Id { get; set; }

    public string? UserCode { get; set; }

    public string? PollingTokenHash { get; set; }

    public QrLoginStatus Status { get; set; }

    public Guid? ApprovedByUserId { get; set; }

    public DateTime ExpiresAtUtc { get; set; }

    public DateTime? ConsumedAt { get; set; }

    public string? UserAgent { get; set; }
    public string? IpAddress { get; set; }
    public string? DeviceLabel { get; set; }
    public string? Browser { get; set; }
    public string? OS { get; set; }
}
