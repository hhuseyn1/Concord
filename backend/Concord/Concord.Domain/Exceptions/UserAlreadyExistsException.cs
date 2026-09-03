namespace Concord.Domain.Exceptions;

public class UserAlreadyExistsException(string email)
    : AlreadyExistsException($"User '{email}' already exists.")
{ }
