namespace Concord.Domain.Exceptions;

public class FriendRequestsDisabledException()
    : ForbiddenException("This user isn't accepting friend requests from you.")
{ }
