namespace Concord.Domain.Exceptions;

public class MemberTimedOutException(DateTime until)
    : ForbiddenException($"You are timed out on this server until {until:u}.")
{ }
