using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0/Servers/{serverId:guid}/Channels")]
[Authorize]
public class ChannelsController(ChannelsService channelsService) : BaseApiController
{
    private readonly ChannelsService _channelsService = channelsService;

    [HttpGet]
    public async Task<List<ChannelResponse>> GetChannelsForServerAsync(Guid serverId)
    {
        return await _channelsService.GetChannelsForServerAsync(GetUserId(), serverId);
    }

    [HttpPost]
    public async Task<ChannelResponse> CreateChannelAsync(Guid serverId, CreateChannelRequest request)
    {
        return await _channelsService.CreateChannelAsync(GetUserId(), serverId, request);
    }

    [HttpPut("{channelId:guid}")]
    public async Task<ChannelResponse> UpdateChannelAsync(Guid serverId, Guid channelId, UpdateChannelRequest request)
    {
        return await _channelsService.UpdateChannelAsync(GetUserId(), serverId, channelId, request);
    }

    [HttpDelete("{channelId:guid}")]
    public async Task DeleteChannelAsync(Guid serverId, Guid channelId)
    {
        await _channelsService.DeleteChannelAsync(GetUserId(), serverId, channelId);
    }

    [HttpPost("Reorder")]
    public async Task ReorderChannelsAsync(Guid serverId, ReorderChannelsRequest request)
    {
        await _channelsService.ReorderChannelsAsync(GetUserId(), serverId, request);
    }
}
