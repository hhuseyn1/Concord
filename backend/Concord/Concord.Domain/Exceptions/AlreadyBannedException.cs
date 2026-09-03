namespace Concord.Domain.Exceptions;

public class AlreadyBannedException() : AlreadyExistsException("That user is already banned from this server.")
{ }
