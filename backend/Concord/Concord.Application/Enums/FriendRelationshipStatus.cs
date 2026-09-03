namespace Concord.Application.Enums;

public enum FriendRelationshipStatus
{
    None,
    Friends,
    OutgoingRequest,
    IncomingRequest,
    // Only ever set when the *viewer* blocked this profile's user (not the reverse) - search already
    // excludes blocked-either-direction results entirely (never needs this value), but a profile can
    // still be opened another way (an existing DM, a message sender) after a block.
    Blocked
}
