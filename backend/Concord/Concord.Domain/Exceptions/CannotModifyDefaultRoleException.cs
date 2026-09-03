namespace Concord.Domain.Exceptions;

public class CannotModifyDefaultRoleException()
    : ForbiddenException("The default role cannot be renamed, deleted, repositioned, or assigned directly.")
{ }
