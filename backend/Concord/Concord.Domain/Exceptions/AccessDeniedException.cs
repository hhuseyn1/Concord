namespace Concord.Domain.Exceptions;

public class AccessDeniedException()
    : ForbiddenException("You do not have permission to perform this operation.")
{ }
