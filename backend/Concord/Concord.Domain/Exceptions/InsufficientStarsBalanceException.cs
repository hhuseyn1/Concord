namespace Concord.Domain.Exceptions;

public class InsufficientStarsBalanceException()
    : ParameterValidationException("amount", "You do not have enough Stars to perform this operation.")
{ }
