namespace Concord.Domain.Exceptions;

public class FriendRequestAlreadyExistsException()
    : AlreadyExistsException("A friend request or friendship already exists between these users.")
{ }
