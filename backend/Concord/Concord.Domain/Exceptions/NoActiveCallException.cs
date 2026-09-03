namespace Concord.Domain.Exceptions;

public class NoActiveCallException()
    : ForbiddenException("There is no active call for this conversation.")
{ }
