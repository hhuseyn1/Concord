using Concord.Application.Enums;

namespace Concord.Domain.Entities;

public class FriendRequest : BaseEntity
{
    public Guid Id { get; set; }

    public Guid RequesterId { get; set; }
    public Guid AddresseeId { get; set; }

    public FriendRequestStatus Status { get; set; }
}
