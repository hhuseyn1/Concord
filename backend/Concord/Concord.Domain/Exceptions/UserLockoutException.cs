namespace Concord.Domain.Exceptions;

public class UserLockoutException(Guid userId)
    : UnauthorizedAccessException($"User '{userId}' has exceeded the number of allowed authentication attempts.")
{ }
