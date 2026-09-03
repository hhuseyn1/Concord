namespace Concord.Domain.Exceptions;

public class CannotLeaveAsOwnerException()
    : ForbiddenException("The owner cannot leave the server. Transfer ownership or delete the server instead.")
{ }
