namespace Concord.Domain.Exceptions;

public abstract class AlreadyExistsException(string message) : Exception(message);
