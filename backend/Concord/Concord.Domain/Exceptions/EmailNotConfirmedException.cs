namespace Concord.Domain.Exceptions;

public class EmailNotConfirmedException()
    : UnauthorizedAccessException("Please verify your email address before logging in.")
{ }
