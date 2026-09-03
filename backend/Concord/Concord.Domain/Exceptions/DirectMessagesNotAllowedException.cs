namespace Concord.Domain.Exceptions;

public class DirectMessagesNotAllowedException()
    : ForbiddenException("This user isn't accepting direct messages from you.")
{ }
