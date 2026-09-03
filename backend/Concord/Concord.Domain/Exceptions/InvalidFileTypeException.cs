namespace Concord.Domain.Exceptions;

public class InvalidFileTypeException()
    : ParameterValidationException("file", "This file type is not allowed for this upload.")
{ }
