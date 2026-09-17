using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Application.Realtime;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Extensions;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

public class ChannelsService(ApplicationDbContext context, ServersService serversService, IServersRealtimeNotifier realtimeNotifier)
{
    private readonly ApplicationDbContext _context = context;
    private readonly ServersService _serversService = serversService;
    private readonly IServersRealtimeNotifier _realtimeNotifier = realtimeNotifier;

    public async Task<ChannelResponse> CreateChannelAsync(Guid currentUserId, Guid serverId, CreateChannelRequest request)
    {
        await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.ManageChannels);

        if (string.IsNullOrWhiteSpace(request.Name))
            throw new ParameterValidationException(nameof(request.Name));

        var highestPosition = await _context.Channels
            .Where(channel => channel.ServerId == serverId && channel.Type == request.Type)
            .MaxAsync(channel => (int?)channel.Position);

        var nextPosition = highestPosition is { } value ? value + 1 : 0;

        var channel = new Channel
        {
            ServerId = serverId,
            Name = request.Name,
            Type = request.Type,
            Position = nextPosition
        };

        _context.Channels.Add(channel);

        await _context.SaveChangesAsync();

        var result = channel.MapToResponse();

        await _realtimeNotifier.ChannelCreatedAsync(serverId, result);

        return result;
    }

    public async Task<ChannelResponse> UpdateChannelAsync(Guid currentUserId, Guid serverId, Guid channelId, UpdateChannelRequest request)
    {
        await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.ManageChannels);

        if (string.IsNullOrWhiteSpace(request.Name))
            throw new ParameterValidationException(nameof(request.Name));

        var channel = await GetChannelInServerAsync(serverId, channelId);

        channel.Name = request.Name;

        await _context.SaveChangesAsync();

        var result = channel.MapToResponse();

        await _realtimeNotifier.ChannelUpdatedAsync(serverId, result);

        return result;
    }

    public async Task DeleteChannelAsync(Guid currentUserId, Guid serverId, Guid channelId)
    {
        await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.ManageChannels);

        var channel = await GetChannelInServerAsync(serverId, channelId);

        _context.Channels.Remove(channel);

        await _context.SaveChangesAsync();

        await _realtimeNotifier.ChannelDeletedAsync(serverId, channelId);
    }

    public async Task<List<ChannelResponse>> GetChannelsForServerAsync(Guid currentUserId, Guid serverId)
    {
        await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.ViewChannels);

        var channels = await _context.Channels
            .Where(channel => channel.ServerId == serverId)
            .OrderBy(channel => channel.Type)
            .ThenBy(channel => channel.Position)
            .ToListAsync();

        var result = new List<ChannelResponse>(channels.Count);
        foreach (var channel in channels)
        {
            var unreadCount = channel.Type == ChannelType.Voice
                ? 0
                : await GetUnreadCountAsync(channel.Id, currentUserId);
            result.Add(channel.MapToResponse(unreadCount));
        }

        return result;
    }

    public async Task ReorderChannelsAsync(Guid currentUserId, Guid serverId, ReorderChannelsRequest request)
    {
        await _serversService.AssertPermissionAsync(currentUserId, serverId, ServerPermission.ManageChannels);

        if (request.ChannelIds.Count == 0 || request.ChannelIds.Distinct().Count() != request.ChannelIds.Count)
            throw new ParameterValidationException(nameof(request.ChannelIds));

        var channels = await _context.Channels
            .Where(channel => channel.ServerId == serverId && request.ChannelIds.Contains(channel.Id))
            .ToListAsync();

        if (channels.Count != request.ChannelIds.Count)
            throw new ChannelNotFoundException();

        var type = channels[0].Type;

        if (channels.Any(channel => channel.Type != type))
            throw new ParameterValidationException(nameof(request.ChannelIds));

        var totalChannelsOfType = await _context.Channels
            .CountAsync(channel => channel.ServerId == serverId && channel.Type == type);

        if (totalChannelsOfType != request.ChannelIds.Count)
            throw new ParameterValidationException(nameof(request.ChannelIds));

        var channelsById = channels.ToDictionary(channel => channel.Id);

        for (var index = 0; index < request.ChannelIds.Count; index++)
            channelsById[request.ChannelIds[index]].Position = index;

        await _context.SaveChangesAsync();

        foreach (var channel in channels)
            await _realtimeNotifier.ChannelUpdatedAsync(serverId, channel.MapToResponse());
    }

    private async Task<int> GetUnreadCountAsync(Guid channelId, Guid userId)
    {
        var lastReadAtUtc = await _context.ChannelReadStates
            .Where(state => state.ChannelId == channelId && state.UserId == userId)
            .Select(state => (DateTime?)state.LastReadAtUtc)
            .FirstOrDefaultAsync();

        return await _context.Messages.CountAsync(message =>
            message.ChannelId == channelId && (lastReadAtUtc == null || message.Created > lastReadAtUtc));
    }

    private async Task<Channel> GetChannelInServerAsync(Guid serverId, Guid channelId)
    {
        var channel = await _context.Channels
            .FirstOrDefaultAsync(channel => channel.Id == channelId);

        if (channel is null || channel.ServerId != serverId)
            throw new ChannelNotFoundException();

        return channel;
    }

    public async Task<Channel> AssertChannelMemberAsync(Guid currentUserId, Guid channelId)
    {
        return await AssertChannelPermissionAsync(currentUserId, channelId, ServerPermission.ViewChannels);
    }

    public async Task<Channel> AssertChannelPermissionAsync(Guid currentUserId, Guid channelId, ServerPermission required)
    {
        var channel = await _context.Channels
            .FirstOrDefaultAsync(channel => channel.Id == channelId);

        if (channel is null)
            throw new ChannelNotFoundException();

        await _serversService.AssertPermissionAsync(currentUserId, channel.ServerId, ServerPermission.ViewChannels | required);

        return channel;
    }
}
