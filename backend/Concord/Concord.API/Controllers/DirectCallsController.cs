using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0/DirectMessages/Conversations/{conversationId:guid}/Calls")]
[Authorize]
public class DirectCallsController(DirectCallsService directCallsService) : BaseApiController
{
    private readonly DirectCallsService _directCallsService = directCallsService;

    [HttpPost]
    public async Task<CallResponse> StartCallAsync(Guid conversationId, StartCallRequest request)
    {
        return await _directCallsService.StartCallAsync(GetUserId(), conversationId, request);
    }

    [HttpPost("{callId:guid}:Accept")]
    public async Task<CallResponse> AcceptAsync(Guid conversationId, Guid callId)
    {
        return await _directCallsService.AcceptAsync(GetUserId(), callId);
    }

    [HttpPost("{callId:guid}:Decline")]
    public async Task<CallResponse> DeclineAsync(Guid conversationId, Guid callId)
    {
        return await _directCallsService.DeclineAsync(GetUserId(), callId);
    }

    [HttpPost("{callId:guid}:End")]
    public async Task<CallResponse> EndAsync(Guid conversationId, Guid callId)
    {
        return await _directCallsService.EndAsync(GetUserId(), callId);
    }

    [HttpGet]
    public async Task<PagedResult<CallResponse>> GetCallsAsync(Guid conversationId, int page, int pageSize)
    {
        return await _directCallsService.GetCallsAsync(GetUserId(), conversationId, page, pageSize);
    }
}
