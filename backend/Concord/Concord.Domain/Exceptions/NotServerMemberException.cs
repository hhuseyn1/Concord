namespace Concord.Domain.Exceptions;

public class NotServerMemberException()
    : ForbiddenException("You are not a member of this server.")
{ }
