namespace Concord.Domain.Exceptions;

public class NotMessageAuthorException()
    : ForbiddenException("You are not the author of this message.")
{ }
