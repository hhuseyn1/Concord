namespace Concord.Domain.Exceptions;

public class TwoFactorNotEnabledException()
    : ParameterValidationException("twoFactor", "Two-factor authentication is not enabled on this account.")
{ }
