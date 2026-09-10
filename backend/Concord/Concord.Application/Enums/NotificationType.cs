namespace Concord.Application.Enums;

// Appended, never reordered/inserted: hub payloads (unlike REST) serialize this as its integer
// ordinal (see FriendsService/NotificationsHub client doc comments on both frontend and mobile) -
// changing an existing member's position would silently reinterpret it as a different type client-side.
public enum NotificationType
{
    FriendRequestReceived,
    FriendRequestAccepted,
    MissedCall,
    Mention,
    FriendRequestDeclined,
    FriendRequestCancelled,
    DirectMessageReceived
}
