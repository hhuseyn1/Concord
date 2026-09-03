namespace Concord.Domain.Exceptions;

public class MemberMutedException()
    : ForbiddenException("You are muted on this server and cannot speak in voice channels.")
{ }
