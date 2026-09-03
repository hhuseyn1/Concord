namespace Concord.Domain.Entities;

/// <summary>
/// Assignment of one <see cref="Role"/> to one <see cref="ServerMember"/>. The default
/// (<c>@everyone</c>) role is implicit and never gets a row here.
/// </summary>
public class ServerMemberRole : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ServerMemberId { get; set; }
    public Guid RoleId { get; set; }
}
