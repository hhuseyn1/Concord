using System.Text;
using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Application.Realtime;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Extensions;
using Concord.Infrastructure.Settings;
using Livekit.Server.Sdk.Dotnet;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace Concord.Infrastructure.Services;

public class VoiceService(
    ApplicationDbContext context,
    ChannelsService channelsService,
    DirectMessagesService directMessagesService,
    PermissionService permissionService,
    RoomServiceClient roomServiceClient,
    IOptions<LiveKitSettings> liveKitOptions,
    IVoiceRealtimeNotifier realtimeNotifier)
{
    public const string DirectCallRoomPrefix = "dm:";

    private readonly ApplicationDbContext _context = context;
    private readonly ChannelsService _channelsService = channelsService;
    private readonly DirectMessagesService _directMessagesService = directMessagesService;
    private readonly PermissionService _permissionService = permissionService;
    private readonly RoomServiceClient _roomServiceClient = roomServiceClient;
    private readonly LiveKitSettings _liveKitSettings = liveKitOptions.Value;
    private readonly IVoiceRealtimeNotifier _realtimeNotifier = realtimeNotifier;

    public async Task<VoiceTokenResponse> GenerateTokenAsync(Guid userId, Guid channelId)
    {
        var channel = await _channelsService.AssertChannelPermissionAsync(userId, channelId, ServerPermission.Connect);

        if (channel.Type != ChannelType.Voice)
            throw new ChannelNotVoiceException();

        var canSpeak = (await _permissionService.ResolveAsync(userId, channel.ServerId)).Has(ServerPermission.Speak);

        return await MintTokenAsync(userId, channelId.ToString(), canSpeak);
    }

    public async Task<List<VoiceParticipantSummary>> GetParticipantsAsync(Guid userId, Guid channelId)
    {
        var channel = await _channelsService.AssertChannelMemberAsync(userId, channelId);

        if (channel.Type != ChannelType.Voice)
            throw new ChannelNotVoiceException();

        return await ListParticipantsAsync(channelId.ToString());
    }

    public async Task<VoiceTokenResponse> GenerateDirectCallTokenAsync(Guid userId, Guid conversationId)
    {
        await _directMessagesService.AssertConversationAccessAsync(userId, conversationId);

        var hasAcceptedCall = await _context.Calls.AnyAsync(call =>
            call.ConversationId == conversationId && call.Status == CallStatus.Accepted);

        if (!hasAcceptedCall)
            throw new NoActiveCallException();

        return await MintTokenAsync(userId, DirectCallRoomPrefix + conversationId);
    }

    public async Task<List<VoiceParticipantSummary>> GetDirectCallParticipantsAsync(Guid userId, Guid conversationId)
    {
        await _directMessagesService.AssertConversationAccessAsync(userId, conversationId);

        return await ListParticipantsAsync(DirectCallRoomPrefix + conversationId);
    }

    public async Task<bool> HandleWebhookAsync(byte[] rawBody, string authHeader)
    {
        WebhookEvent webhookEvent;

        try
        {
            webhookEvent = await VerifyAndParseWebhookAsync(rawBody, authHeader);
        }
        catch (Exception)
        {
            return false;
        }

        if (webhookEvent.Room is null || webhookEvent.Participant is null)
            return true;

        if (!Guid.TryParse(webhookEvent.Participant.Identity, out var userId))
            return true;

        var roomName = webhookEvent.Room.Name;

        if (roomName.StartsWith(DirectCallRoomPrefix, StringComparison.Ordinal))
        {
            if (!Guid.TryParse(roomName[DirectCallRoomPrefix.Length..], out var conversationId))
                return true;

            var (userAId, userBId) = await _directMessagesService.GetConversationParticipantsAsync(conversationId);

            switch (webhookEvent.Event)
            {
                case "participant_joined":
                    await _realtimeNotifier.DirectCallParticipantJoinedAsync(userAId, userBId, conversationId, userId);
                    break;

                case "participant_left":
                    await _realtimeNotifier.DirectCallParticipantLeftAsync(userAId, userBId, conversationId, userId);
                    break;
            }

            return true;
        }

        if (!Guid.TryParse(roomName, out var channelId))
            return true;

        switch (webhookEvent.Event)
        {
            case "participant_joined":
                await _realtimeNotifier.VoiceParticipantJoinedAsync(channelId, userId);
                break;

            case "participant_left":
                await _realtimeNotifier.VoiceParticipantLeftAsync(channelId, userId);
                break;
        }

        return true;
    }

    private Task<WebhookEvent> VerifyAndParseWebhookAsync(byte[] rawBody, string authHeader)
    {
        var webhookReceiver = new WebhookReceiver(_liveKitSettings.ApiKey, _liveKitSettings.ApiSecret);
        var body = Encoding.UTF8.GetString(rawBody);

        return Task.FromResult(webhookReceiver.Receive(body, authHeader));
    }

    private async Task<VoiceTokenResponse> MintTokenAsync(Guid userId, string room, bool canPublish = true)
    {
        var user = await _context.Users.FirstOrDefaultAsync(user => user.Id == userId);

        if (user is null)
            throw new UserNotFoundException(userId);

        var displayName = GetDisplayName(user);

        var token = new AccessToken(_liveKitSettings.ApiKey, _liveKitSettings.ApiSecret)
            .WithIdentity(userId.ToString())
            .WithName(displayName)
            .WithGrants(new VideoGrants
            {
                RoomJoin = true,
                Room = room,
                CanPublish = canPublish,
                CanSubscribe = true
            });

        return new VoiceTokenResponse
        {
            Token = token.ToJwt(),
            Url = _liveKitSettings.Url
        };
    }

    private async Task<List<VoiceParticipantSummary>> ListParticipantsAsync(string room)
    {
        try
        {
            var response = await _roomServiceClient.ListParticipants(new ListParticipantsRequest { Room = room });

            return response.Participants.Select(participant => participant.MapToSummary()).ToList();
        }
        catch (global::Twirp.Exception ex) when (ex.Message.Contains("does not exist", StringComparison.OrdinalIgnoreCase))
        {
            return [];
        }
    }

    private static string GetDisplayName(User user) =>
        string.IsNullOrWhiteSpace(user.Username) ? $"{user.Name} {user.Surname}".Trim() : user.Username;
}
