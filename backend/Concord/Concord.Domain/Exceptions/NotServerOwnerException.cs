namespace Concord.Domain.Exceptions;

public class NotServerOwnerException()
    : ForbiddenException("You must be the owner of this server to perform this operation.")
{ }
