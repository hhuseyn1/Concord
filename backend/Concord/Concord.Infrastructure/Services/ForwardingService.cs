using Concord.Application.Models;
using Concord.Application.Realtime;
using Concord.Domain.Exceptions;

namespace Concord.Infrastructure.Services;

public class ForwardingService(
    MessagesService messagesService,
    DirectMessagesService directMessagesService,
    IDirectMessagesRealtimeNotifier directMessagesRealtimeNotifier,
    IMessagesRealtimeNotifier messagesRealtimeNotifier)
{
    private readonly MessagesService _messagesService = messagesService;
    private readonly DirectMessagesService _directMessagesService = directMessagesService;
    private readonly IDirectMessagesRealtimeNotifier _directMessagesRealtimeNotifier = directMessagesRealtimeNotifier;
    private readonly IMessagesRealtimeNotifier _messagesRealtimeNotifier = messagesRealtimeNotifier;

    public async Task<object> ForwardFromChannelAsync(Guid currentUserId, Guid sourceChannelId, Guid messageId, ForwardMessageRequest request)
    {
        var (content, attachmentUrl, senderId, createdAt) = await _messagesService.GetForwardableContentAsync(currentUserId, sourceChannelId, messageId);

        var result = await DeliverAsync(currentUserId, request, content, attachmentUrl, senderId, createdAt);

        if (result is MessageResponse forwarded && request.TargetChannelId is Guid targetChannelId)
            await _messagesRealtimeNotifier.MessageReceivedAsync(targetChannelId, forwarded);

        return result;
    }

    public async Task<object> ForwardFromConversationAsync(Guid currentUserId, Guid sourceConversationId, Guid messageId, ForwardMessageRequest request)
    {
        var (content, attachmentUrl, senderId, createdAt) = await _directMessagesService.GetForwardableContentAsync(currentUserId, sourceConversationId, messageId);

        var result = await DeliverAsync(currentUserId, request, content, attachmentUrl, senderId, createdAt);

        if (result is DirectMessageResponse forwarded && request.TargetConversationId is Guid targetConversationId)
        {
            var (userAId, userBId) = await _directMessagesService.GetConversationParticipantsAsync(targetConversationId);
            await _directMessagesRealtimeNotifier.MessageReceivedAsync(userAId, userBId, forwarded);
        }

        return result;
    }

    private async Task<object> DeliverAsync(Guid currentUserId, ForwardMessageRequest request, string? content, string? attachmentUrl, Guid forwardedFromSenderId, DateTime forwardedFromCreatedAt)
    {
        var hasChannelTarget = request.TargetChannelId.HasValue;
        var hasConversationTarget = request.TargetConversationId.HasValue;

        if (hasChannelTarget == hasConversationTarget)
            throw new ParameterValidationException(nameof(request.TargetChannelId), "Exactly one of TargetChannelId or TargetConversationId must be set.");

        if (hasChannelTarget)
            return await _messagesService.ReceiveForwardedMessageAsync(currentUserId, request.TargetChannelId!.Value, content, attachmentUrl, forwardedFromSenderId, forwardedFromCreatedAt);

        return await _directMessagesService.ReceiveForwardedMessageAsync(currentUserId, request.TargetConversationId!.Value, content, attachmentUrl, forwardedFromSenderId, forwardedFromCreatedAt);
    }
}
