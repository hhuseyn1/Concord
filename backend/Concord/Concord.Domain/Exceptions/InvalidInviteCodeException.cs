namespace Concord.Domain.Exceptions;

public class InvalidInviteCodeException()
    : NotFoundException("Invalid or expired invite code.")
{ }
