using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0/DirectMessages/Conversations/{conversationId:guid}/Voice")]
[Authorize]
public class DirectVoiceController(VoiceService voiceService) : BaseApiController
{
    private readonly VoiceService _voiceService = voiceService;

    [HttpPost("Token")]
    public async Task<VoiceTokenResponse> GenerateTokenAsync(Guid conversationId)
    {
        return await _voiceService.GenerateDirectCallTokenAsync(GetUserId(), conversationId);
    }

    [HttpGet("Participants")]
    public async Task<List<VoiceParticipantSummary>> GetParticipantsAsync(Guid conversationId)
    {
        return await _voiceService.GetDirectCallParticipantsAsync(GetUserId(), conversationId);
    }
}
