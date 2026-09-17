namespace Concord.Application.Enums;

[Flags]
public enum ServerPermission : long
{
    None = 0,

    ViewChannels = 1L << 0,

    SendMessages = 1L << 1,

    ManageMessages = 1L << 2,

    ManageChannels = 1L << 3,

    ManageServer = 1L << 4,

    ManageRoles = 1L << 5,

    ManageInvites = 1L << 6,

    KickMembers = 1L << 7,

    BanMembers = 1L << 8,

    MuteMembers = 1L << 9,

    ModerateMembers = 1L << 10,

    Connect = 1L << 11,

    Speak = 1L << 12,

    Administrator = 1L << 13,

    MentionEveryone = 1L << 14
}
