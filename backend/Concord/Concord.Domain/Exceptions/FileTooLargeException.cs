namespace Concord.Domain.Exceptions;

public class FileTooLargeException(long maxSizeBytes)
    : ParameterValidationException("file", $"File exceeds the maximum allowed size of {maxSizeBytes / (1024 * 1024)} MB.")
{ }
