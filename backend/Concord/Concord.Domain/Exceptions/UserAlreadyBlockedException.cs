namespace Concord.Domain.Exceptions;

public class UserAlreadyBlockedException()
    : AlreadyExistsException("User is already blocked.")
{ }
