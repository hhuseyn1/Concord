using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Application.Realtime;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Extensions;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

public class DirectCallsService(
    ApplicationDbContext context,
    DirectMessagesService directMessagesService,
    NotificationsService notificationsService,
    IDirectCallsRealtimeNotifier realtimeNotifier,
    INotificationsRealtimeNotifier notificationsRealtimeNotifier)
{
    private readonly ApplicationDbContext _context = context;
    private readonly DirectMessagesService _directMessagesService = directMessagesService;
    private readonly NotificationsService _notificationsService = notificationsService;
    private readonly IDirectCallsRealtimeNotifier _realtimeNotifier = realtimeNotifier;
    private readonly INotificationsRealtimeNotifier _notificationsRealtimeNotifier = notificationsRealtimeNotifier;

    public async Task<CallResponse> StartCallAsync(Guid callerId, Guid conversationId, StartCallRequest request)
    {
        var conversation = await _directMessagesService.AssertConversationAccessAsync(callerId, conversationId);

        var calleeId = conversation.UserAId == callerId ? conversation.UserBId : conversation.UserAId;

        var call = new Call
        {
            ConversationId = conversationId,
            InitiatorId = callerId,
            CalleeId = calleeId,
            Type = request.Type,
            Status = CallStatus.Ringing
        };

        _context.Calls.Add(call);
        await _context.SaveChangesAsync();

        var result = call.MapToResponse();

        await _realtimeNotifier.CallInitiatedAsync(result.CalleeId, result);

        return result;
    }

    public async Task<CallResponse> AcceptAsync(Guid userId, Guid callId)
    {
        var call = await GetCallAsync(callId);

        if (call.CalleeId != userId)
            throw new NotCallParticipantException();

        if (call.Status != CallStatus.Ringing)
            throw new CallAlreadyAnsweredException();

        call.Status = CallStatus.Accepted;
        call.AnsweredAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        var result = call.MapToResponse();

        await _realtimeNotifier.CallAcceptedAsync(result.InitiatorId, result);

        return result;
    }

    public async Task<CallResponse> DeclineAsync(Guid userId, Guid callId)
    {
        var call = await GetCallAsync(callId);

        if (call.CalleeId != userId)
            throw new NotCallParticipantException();

        if (call.Status != CallStatus.Ringing)
            throw new CallAlreadyAnsweredException();

        call.Status = CallStatus.Declined;
        call.EndedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        var result = call.MapToResponse();

        await _realtimeNotifier.CallDeclinedAsync(result.InitiatorId, result);

        return result;
    }

    public async Task<CallResponse> EndAsync(Guid userId, Guid callId)
    {
        var call = await GetCallAsync(callId);

        if (call.InitiatorId != userId && call.CalleeId != userId)
            throw new NotCallParticipantException();

        if (call.Status == CallStatus.Ringing)
        {
            call.Status = CallStatus.Missed;
            call.EndedAt = DateTime.UtcNow;

            await _notificationsService.NotifyMissedCallAsync(call.CalleeId, call.InitiatorId);
            await _context.SaveChangesAsync();
        }
        else if (call.Status == CallStatus.Accepted)
        {
            call.Status = CallStatus.Ended;
            call.EndedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
        }

        var result = call.MapToResponse();

        await _realtimeNotifier.CallEndedAsync(result.InitiatorId, result.CalleeId, result);

        if (result.Status == CallStatus.Missed)
            await _notificationsRealtimeNotifier.NotifyAsync(result.CalleeId, NotificationType.MissedCall, result.InitiatorId, reason: null);

        return result;
    }

    public async Task<PagedResult<CallResponse>> GetCallsAsync(Guid userId, Guid conversationId, int page, int pageSize)
    {
        await _directMessagesService.AssertConversationAccessAsync(userId, conversationId);

        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        var callsQuery = _context.Calls
            .Where(call => call.ConversationId == conversationId);

        var totalCount = await callsQuery.CountAsync();

        var calls = await callsQuery
            .OrderByDescending(call => call.Created)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<CallResponse>
        {
            Items = calls.Select(call => call.MapToResponse()).ToList(),
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    private async Task<Call> GetCallAsync(Guid callId)
    {
        var call = await _context.Calls.FirstOrDefaultAsync(call => call.Id == callId);

        if (call is null)
            throw new CallNotFoundException();

        return call;
    }
}
