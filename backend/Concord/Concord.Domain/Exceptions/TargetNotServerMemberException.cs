namespace Concord.Domain.Exceptions;

// Distinct from NotServerMemberException, which is worded in the second person for the *caller's own*
// membership (AssertServerMemberAsync). This one is for the several call sites that look up some
// *other* user's membership (a kick/transfer/moderation/role target) - reusing NotServerMemberException
// there told the caller "you are not a member of this server", which is backwards and confusing when
// it's actually the target who isn't a member.
public class TargetNotServerMemberException()
    : ForbiddenException("That user is not a member of this server.")
{ }
