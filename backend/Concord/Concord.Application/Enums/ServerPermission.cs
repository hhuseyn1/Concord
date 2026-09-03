namespace Concord.Application.Enums;

/// <summary>
/// Capabilities a Role can grant inside a single server (P0 RBAC).
/// Stored as a bitfield on <c>Role.Permissions</c> and combined with a bitwise OR across every role
/// a member holds, so permissions are strictly additive - there is no per-role "deny", and no
/// per-channel overwrite (deliberately out of scope; see the P0 decision).
///
/// Values are explicit powers of two and must never be renumbered: they are persisted as a
/// <c>bigint</c>, so changing a value silently rewrites the meaning of every stored role.
/// </summary>
[Flags]
public enum ServerPermission : long
{
    None = 0,

    /// <summary>See channels and read their message history.</summary>
    ViewChannels = 1L << 0,

    /// <summary>Post, edit, and delete one's own messages.</summary>
    SendMessages = 1L << 1,

    /// <summary>Delete or pin *anyone's* messages. Authors can always manage their own.</summary>
    ManageMessages = 1L << 2,

    /// <summary>Create, rename, and delete channels.</summary>
    ManageChannels = 1L << 3,

    /// <summary>Rename the server and change its icon.</summary>
    ManageServer = 1L << 4,

    /// <summary>Create, edit, delete, and assign roles - bounded by role hierarchy.</summary>
    ManageRoles = 1L << 5,

    /// <summary>Create and list invite codes.</summary>
    ManageInvites = 1L << 6,

    /// <summary>Remove a member; they may rejoin with a valid invite.</summary>
    KickMembers = 1L << 7,

    /// <summary>Remove a member and block them from rejoining through any invite.</summary>
    BanMembers = 1L << 8,

    /// <summary>Server-mute a member: they keep Connect but lose Speak.</summary>
    MuteMembers = 1L << 9,

    /// <summary>Time a member out - a temporary, expiring loss of SendMessages and Speak.</summary>
    ModerateMembers = 1L << 10,

    /// <summary>Join voice channels.</summary>
    Connect = 1L << 11,

    /// <summary>Transmit audio/video in voice channels.</summary>
    Speak = 1L << 12,

    /// <summary>Implicitly grants every permission above, present and future.</summary>
    Administrator = 1L << 13,

    /// <summary>Trigger an <c>@everyone</c> mass-notification when sending a channel message.
    /// Deliberately excluded from the default <c>@everyone</c> role (see
    /// <see cref="Concord.Domain.Entities.Role.DefaultRolePermissions"/>) - without this gate any
    /// member could spam a notification to the whole server.</summary>
    MentionEveryone = 1L << 14
}
