namespace Concord.Domain.Exceptions;

public class MessageNotFoundException()
    : NotFoundException("Message not found.")
{ }
