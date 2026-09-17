namespace Concord.Domain.Exceptions;

public class PremiumTrialAlreadyActiveException()
    : AlreadyExistsException("You already have active Premium access.")
{ }
