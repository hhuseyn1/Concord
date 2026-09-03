using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0/Channels/{channelId:guid}/Voice")]
[Authorize]
public class VoiceController(VoiceService voiceService) : BaseApiController
{
    private readonly VoiceService _voiceService = voiceService;

    [HttpPost("Token")]
    public async Task<VoiceTokenResponse> GenerateTokenAsync(Guid channelId)
    {
        return await _voiceService.GenerateTokenAsync(GetUserId(), channelId);
    }

    [HttpGet("Participants")]
    public async Task<List<VoiceParticipantSummary>> GetParticipantsAsync(Guid channelId)
    {
        return await _voiceService.GetParticipantsAsync(GetUserId(), channelId);
    }
}
