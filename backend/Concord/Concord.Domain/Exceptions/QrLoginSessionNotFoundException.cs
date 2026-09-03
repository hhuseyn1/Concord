namespace Concord.Domain.Exceptions;

public class QrLoginSessionNotFoundException()
    : NotFoundException("That sign-in code is invalid or has expired.")
{ }
