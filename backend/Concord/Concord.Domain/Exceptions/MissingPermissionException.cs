using Concord.Application.Enums;

namespace Concord.Domain.Exceptions;

public class MissingPermissionException(ServerPermission permission)
    : ForbiddenException($"You lack the '{permission}' permission on this server.")
{ }
