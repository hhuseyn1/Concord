namespace Concord.Domain.Exceptions;

public class BanNotFoundException() : NotFoundException("That user is not banned from this server.")
{ }
