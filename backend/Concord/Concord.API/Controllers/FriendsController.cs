using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0/Friends")]
[Authorize]
public class FriendsController(FriendsService friendsService) : BaseApiController
{
    private readonly FriendsService _friendsService = friendsService;

    [HttpPost("Requests/{targetUserId:guid}")]
    public async Task<SendRequestResponse> SendRequestAsync(Guid targetUserId)
    {
        return await _friendsService.SendRequestAsync(GetUserId(), targetUserId);
    }

    [HttpPost("Requests/{requestId:guid}:Accept")]
    public async Task AcceptRequestAsync(Guid requestId)
    {
        await _friendsService.AcceptRequestAsync(GetUserId(), requestId);
    }

    [HttpPost("Requests/{requestId:guid}:Decline")]
    public async Task DeclineRequestAsync(Guid requestId)
    {
        await _friendsService.DeclineRequestAsync(GetUserId(), requestId);
    }

    [HttpDelete("Requests/{requestId:guid}")]
    public async Task CancelRequestAsync(Guid requestId)
    {
        await _friendsService.CancelRequestAsync(GetUserId(), requestId);
    }

    [HttpGet("Requests/Incoming")]
    public async Task<List<FriendRequestSummary>> GetIncomingRequestsAsync()
    {
        return await _friendsService.GetIncomingRequestsAsync(GetUserId());
    }

    [HttpGet("Requests/Outgoing")]
    public async Task<List<FriendRequestSummary>> GetOutgoingRequestsAsync()
    {
        return await _friendsService.GetOutgoingRequestsAsync(GetUserId());
    }

    [HttpGet]
    public async Task<PagedResult<PublicProfileResponse>> GetFriendsListAsync(int page, int pageSize)
    {
        return await _friendsService.GetFriendsListAsync(GetUserId(), page, pageSize);
    }

    [HttpPost("Blocks/{targetUserId:guid}")]
    public async Task BlockUserAsync(Guid targetUserId)
    {
        await _friendsService.BlockUserAsync(GetUserId(), targetUserId);
    }

    [HttpDelete("Blocks/{targetUserId:guid}")]
    public async Task UnblockUserAsync(Guid targetUserId)
    {
        await _friendsService.UnblockUserAsync(GetUserId(), targetUserId);
    }

    [HttpGet("Blocks")]
    public async Task<PagedResult<PublicProfileResponse>> GetBlockedListAsync(int page, int pageSize)
    {
        return await _friendsService.GetBlockedListAsync(GetUserId(), page, pageSize);
    }
}
