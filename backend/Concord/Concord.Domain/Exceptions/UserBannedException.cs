namespace Concord.Domain.Exceptions;

public class UserBannedException()
    : ForbiddenException("You are banned from this server.")
{ }
