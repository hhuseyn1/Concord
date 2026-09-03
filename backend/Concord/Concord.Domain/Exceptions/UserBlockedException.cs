namespace Concord.Domain.Exceptions;

public class UserBlockedException()
    : ForbiddenException("You do not have permission to perform this operation.")
{ }
