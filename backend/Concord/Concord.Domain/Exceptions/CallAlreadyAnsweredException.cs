namespace Concord.Domain.Exceptions;

public class CallAlreadyAnsweredException()
    : AlreadyExistsException("This call has already been answered.")
{ }
