namespace Concord.Domain.Exceptions;

public class ParameterValidationException : Exception
{
    public ParameterValidationException(string parameter)
        : base($"'{parameter}' validation error.")
    { }

    public ParameterValidationException(string parameter, string message)
        : base($"{message} (parameter '{parameter}')")
    { }
}