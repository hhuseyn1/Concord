namespace Concord.Domain.Exceptions;

public class InvalidCurrentPasswordException() : UnauthorizedAccessException("Current password is incorrect.")
{ }
