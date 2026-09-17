namespace Concord.Domain.Exceptions;

public class RoleHierarchyException()
    : ForbiddenException("You cannot act on a role or member ranked at or above your highest role.")
{ }
