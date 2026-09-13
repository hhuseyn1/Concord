using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0/Billing/Webhook")]
public class BillingWebhookController(BillingService billingService) : BaseApiController
{
    private readonly BillingService _billingService = billingService;

    [HttpPost]
    public async Task<IActionResult> HandleWebhookAsync()
    {
        using var memoryStream = new MemoryStream();
        await Request.Body.CopyToAsync(memoryStream);
        var rawBody = memoryStream.ToArray();

        var signatureHeader = Request.Headers["Stripe-Signature"].ToString();

        try
        {
            await _billingService.HandleWebhookAsync(rawBody, signatureHeader);
        }
        catch (Stripe.StripeException)
        {
            return Unauthorized();
        }

        return Ok();
    }
}
