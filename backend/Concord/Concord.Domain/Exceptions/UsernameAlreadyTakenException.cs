namespace Concord.Domain.Exceptions;

public class UsernameAlreadyTakenException(string username)
    : AlreadyExistsException($"Username '{username}' is already taken.")
{ }
