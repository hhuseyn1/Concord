namespace Concord.Domain.Exceptions;

/// <summary>
/// Raised when a request acts on a QR sign-in that is not in a state that permits it - already
/// approved, denied, consumed, or expired.
/// </summary>
public class QrLoginNotApprovedException(string message) : ForbiddenException(message)
{ }
