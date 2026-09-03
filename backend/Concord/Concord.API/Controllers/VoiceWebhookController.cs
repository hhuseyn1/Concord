using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0/Voice/Webhook")]
public class VoiceWebhookController(VoiceService voiceService) : BaseApiController
{
    private readonly VoiceService _voiceService = voiceService;

    [HttpPost]
    public async Task<IActionResult> HandleWebhookAsync()
    {
        using var memoryStream = new MemoryStream();
        await Request.Body.CopyToAsync(memoryStream);
        var rawBody = memoryStream.ToArray();

        var authHeader = Request.Headers["Authorization"].ToString();

        var handled = await _voiceService.HandleWebhookAsync(rawBody, authHeader);

        return handled ? Ok() : Unauthorized();
    }
}
