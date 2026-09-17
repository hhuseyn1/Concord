namespace Concord.Domain.Exceptions;

public class TargetNotServerMemberException()
    : ForbiddenException("That user is not a member of this server.")
{ }
