namespace Concord.Domain.Exceptions;

public class SessionNotFoundException()
    : NotFoundException("Session not found.")
{ }
