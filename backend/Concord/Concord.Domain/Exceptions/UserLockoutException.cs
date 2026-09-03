namespace Concord.Domain.Exceptions;

// Inherits UnauthorizedAccessException (not a plain Exception) so
// GlobalExceptionHandlingMiddleware maps it to 401, matching every other
// "can't authenticate right now" case from POST /Login (bad credentials,
// disabled account, no password set) instead of falling through to its
// generic 500 handler. Both clients previously worked around the 500 by
// string-matching this exact message (see ApiException.isLikelyAccountLockout
// on mobile / authErrors.js on web) - that workaround stays harmless now
// that the status code is also correct, but is no longer load-bearing.
public class UserLockoutException(Guid userId)
    : UnauthorizedAccessException($"User '{userId}' has exceeded the number of allowed authentication attempts.")
{ }
