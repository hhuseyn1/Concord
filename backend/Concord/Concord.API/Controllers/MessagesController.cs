using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0/Servers/{serverId:guid}/Channels/{channelId:guid}/Messages")]
[Authorize]
public class MessagesController(MessagesService messagesService, ForwardingService forwardingService) : BaseApiController
{
    private readonly MessagesService _messagesService = messagesService;
    private readonly ForwardingService _forwardingService = forwardingService;

    [HttpGet]
    public async Task<PagedResult<MessageResponse>> GetMessagesAsync(Guid channelId, int page, int pageSize)
    {
        return await _messagesService.GetMessagesAsync(GetUserId(), channelId, page, pageSize);
    }

    [HttpPost]
    public async Task<MessageResponse> SendMessageAsync(Guid serverId, Guid channelId, SendMessageRequest request)
    {
        return await _messagesService.SendMessageAsync(GetUserId(), serverId, channelId, request);
    }

    [HttpPost("{messageId:guid}/Forward")]
    public async Task<object> ForwardMessageAsync(Guid channelId, Guid messageId, ForwardMessageRequest request)
    {
        return await _forwardingService.ForwardFromChannelAsync(GetUserId(), channelId, messageId, request);
    }

    [HttpPost("{messageId:guid}:Pin")]
    public async Task<MessageResponse> PinMessageAsync(Guid channelId, Guid messageId)
    {
        return await _messagesService.PinMessageAsync(GetUserId(), channelId, messageId);
    }

    [HttpPost("{messageId:guid}:Unpin")]
    public async Task<MessageResponse> UnpinMessageAsync(Guid channelId, Guid messageId)
    {
        return await _messagesService.UnpinMessageAsync(GetUserId(), channelId, messageId);
    }

    [HttpGet("Pinned")]
    public async Task<List<MessageResponse>> GetPinnedMessagesAsync(Guid channelId)
    {
        return await _messagesService.GetPinnedMessagesAsync(GetUserId(), channelId);
    }

    [HttpPut("{messageId:guid}")]
    public async Task<MessageResponse> EditMessageAsync(Guid channelId, Guid messageId, EditMessageRequest request)
    {
        return await _messagesService.EditMessageAsync(GetUserId(), channelId, messageId, request);
    }

    [HttpDelete("{messageId:guid}")]
    public async Task<bool> DeleteMessageAsync(Guid channelId, Guid messageId)
    {
        return await _messagesService.DeleteMessageAsync(GetUserId(), channelId, messageId);
    }

    [HttpPost("{messageId:guid}/Reactions")]
    public async Task<MessageResponse> ToggleReactionAsync(Guid channelId, Guid messageId, ReactionRequest request)
    {
        return await _messagesService.ToggleReactionAsync(GetUserId(), channelId, messageId, request);
    }
}
