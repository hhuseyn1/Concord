namespace Concord.Domain.Exceptions;

public class TwoFactorSetupNotStartedException()
    : ParameterValidationException("twoFactor", "Start two-factor setup before confirming a code.")
{ }
