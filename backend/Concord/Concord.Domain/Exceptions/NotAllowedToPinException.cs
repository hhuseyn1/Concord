namespace Concord.Domain.Exceptions;

public class NotAllowedToPinException()
    : ForbiddenException("You are not allowed to pin or unpin this message.")
{ }
