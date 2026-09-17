namespace Concord.Domain.Exceptions;

/// <summary>Stars transfers are scoped to friends only, mirroring the product's existing
/// friends-first social surface.</summary>
public class NotFriendsException()
    : ForbiddenException("You can only send Stars to a friend.")
{ }
