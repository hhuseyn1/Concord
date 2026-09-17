namespace Concord.Domain.Entities;

public class ServerMemberRole : BaseEntity
{
    public Guid Id { get; set; }

    public Guid ServerMemberId { get; set; }
    public Guid RoleId { get; set; }
}
