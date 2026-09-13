namespace Concord.Domain.Exceptions;

public class SubscriptionAlreadyActiveException(Guid userId)
    : AlreadyExistsException($"User '{userId}' already has an active subscription.")
{ }
