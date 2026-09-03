namespace Concord.Domain.Exceptions;

public class CannotDisableSelfException()
    : ParameterValidationException("userId", "You cannot disable your own admin account.")
{ }
