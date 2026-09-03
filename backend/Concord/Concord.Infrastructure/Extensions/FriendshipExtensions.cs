using Concord.Application.Models;
using Concord.Domain.Entities;

namespace Concord.Infrastructure.Extensions;

public static class FriendshipExtensions
{
    public static FriendRequestSummary MapToSummary(this FriendRequest request, User otherUser, UserPresence? presence) => new()
    {
        Id = request.Id,
        User = otherUser.MapToPublicModel(presence),
        Created = request.Created
    };
}
