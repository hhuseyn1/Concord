namespace Concord.Domain.Exceptions;

/// <summary>
/// Raised when a member tries to act on a role - or on another member - that ranks at or above their
/// own highest role. Keeps ManageRoles from being a backdoor to self-promotion.
/// </summary>
public class RoleHierarchyException()
    : ForbiddenException("You cannot act on a role or member ranked at or above your highest role.")
{ }
