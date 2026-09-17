namespace Concord.Domain.Exceptions;

public class NotFriendsException()
    : ForbiddenException("You can only send Stars to a friend.")
{ }
