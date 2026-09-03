namespace Concord.Domain.Exceptions;

public abstract class ForbiddenException(string message) : Exception(message);