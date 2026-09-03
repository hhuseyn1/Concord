namespace Concord.Domain.Exceptions;

public class InvalidRoleException() : ParameterValidationException("role", "That role is not valid.")
{ }
