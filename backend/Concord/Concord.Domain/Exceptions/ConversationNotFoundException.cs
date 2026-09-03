namespace Concord.Domain.Exceptions;

public class ConversationNotFoundException()
    : NotFoundException("Conversation not found.")
{ }
