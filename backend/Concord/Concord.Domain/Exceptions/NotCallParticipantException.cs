namespace Concord.Domain.Exceptions;

public class NotCallParticipantException()
    : ForbiddenException("You do not have permission to perform this operation.")
{ }
