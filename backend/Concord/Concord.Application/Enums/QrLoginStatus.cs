namespace Concord.Application.Enums;

public enum QrLoginStatus
{
    /// <summary>Displayed on the signing-in device; nobody has acted on it yet.</summary>
    Pending,

    /// <summary>A signed-in device approved it. The waiting browser may now collect its session.</summary>
    Approved,

    /// <summary>A signed-in device explicitly rejected it - terminal, and never retried.</summary>
    Denied,

    /// <summary>The session was collected. Terminal: the approval is spent and cannot be reused.</summary>
    Consumed
}
