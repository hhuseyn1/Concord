namespace Concord.Domain.Exceptions;

public class InvalidTwoFactorCodeException()
    : ParameterValidationException("code", "That code is not valid. Check your authenticator app and try again.")
{ }
