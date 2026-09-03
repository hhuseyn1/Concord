using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0/DirectMessages")]
[Authorize]
public class DirectMessagesController(DirectMessagesService directMessagesService, ForwardingService forwardingService) : BaseApiController
{
    private readonly DirectMessagesService _directMessagesService = directMessagesService;
    private readonly ForwardingService _forwardingService = forwardingService;

    [HttpGet("Conversations")]
    public async Task<PagedResult<ConversationResponse>> GetConversationsAsync([FromQuery] int page, [FromQuery] int pageSize)
    {
        return await _directMessagesService.GetConversationsAsync(GetUserId(), page, pageSize);
    }

    [HttpPost("Conversations/{userId:guid}")]
    public async Task<ConversationResponse> CreateOrGetConversationAsync(Guid userId)
    {
        return await _directMessagesService.CreateOrGetConversationAsync(GetUserId(), userId);
    }

    [HttpGet("Conversations/{conversationId:guid}/Messages")]
    public async Task<PagedResult<DirectMessageResponse>> GetMessagesAsync(Guid conversationId, [FromQuery] int page, [FromQuery] int pageSize)
    {
        return await _directMessagesService.GetMessagesAsync(GetUserId(), conversationId, page, pageSize);
    }

    [HttpGet("Conversations/{conversationId:guid}/Messages/Search")]
    public async Task<PagedResult<DirectMessageResponse>> SearchMessagesAsync(Guid conversationId, [FromQuery] string query, [FromQuery] int page, [FromQuery] int pageSize)
    {
        return await _directMessagesService.SearchMessagesAsync(GetUserId(), conversationId, query, page, pageSize);
    }

    [HttpPost("Conversations/{conversationId:guid}/Messages")]
    public async Task<DirectMessageResponse> SendMessageAsync(Guid conversationId, SendMessageRequest request)
    {
        return await _directMessagesService.SendMessageAsync(GetUserId(), conversationId, request);
    }

    [HttpPost("Conversations/{conversationId:guid}/Messages/{messageId:guid}/Forward")]
    public async Task<object> ForwardMessageAsync(Guid conversationId, Guid messageId, ForwardMessageRequest request)
    {
        return await _forwardingService.ForwardFromConversationAsync(GetUserId(), conversationId, messageId, request);
    }

    [HttpPost("Conversations/{conversationId:guid}/Messages/{messageId:guid}:Pin")]
    public async Task<DirectMessageResponse> PinMessageAsync(Guid conversationId, Guid messageId)
    {
        return await _directMessagesService.PinMessageAsync(GetUserId(), conversationId, messageId);
    }

    [HttpPost("Conversations/{conversationId:guid}/Messages/{messageId:guid}:Unpin")]
    public async Task<DirectMessageResponse> UnpinMessageAsync(Guid conversationId, Guid messageId)
    {
        return await _directMessagesService.UnpinMessageAsync(GetUserId(), conversationId, messageId);
    }

    [HttpGet("Conversations/{conversationId:guid}/Messages/Pinned")]
    public async Task<List<DirectMessageResponse>> GetPinnedMessagesAsync(Guid conversationId)
    {
        return await _directMessagesService.GetPinnedMessagesAsync(GetUserId(), conversationId);
    }

    [HttpPut("Conversations/{conversationId:guid}/Messages/{messageId:guid}")]
    public async Task<DirectMessageResponse> EditMessageAsync(Guid conversationId, Guid messageId, EditMessageRequest request)
    {
        return await _directMessagesService.EditMessageAsync(GetUserId(), conversationId, messageId, request);
    }

    [HttpDelete("Conversations/{conversationId:guid}/Messages/{messageId:guid}")]
    public async Task<bool> DeleteMessageAsync(Guid conversationId, Guid messageId)
    {
        return await _directMessagesService.DeleteMessageAsync(GetUserId(), conversationId, messageId);
    }

    [HttpPost("Conversations/{conversationId:guid}/Messages/{messageId:guid}/Reactions")]
    public async Task<DirectMessageResponse> ToggleReactionAsync(Guid conversationId, Guid messageId, ReactionRequest request)
    {
        return await _directMessagesService.ToggleReactionAsync(GetUserId(), conversationId, messageId, request);
    }
}
