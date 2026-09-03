namespace Concord.Domain.Exceptions;

public class CannotTargetSelfException()
    : ParameterValidationException("targetUserId", "You cannot perform this operation on yourself.")
{ }
