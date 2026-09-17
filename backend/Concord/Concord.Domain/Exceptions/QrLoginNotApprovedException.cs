namespace Concord.Domain.Exceptions;

public class QrLoginNotApprovedException(string message) : ForbiddenException(message)
{ }
