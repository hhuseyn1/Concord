using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;

[Route("Api/V1.0/Billing")]
[Authorize]
public class BillingController(BillingService billingService) : BaseApiController
{
    private readonly BillingService _billingService = billingService;

    [HttpPost("CheckoutSession")]
    public async Task<CheckoutSessionResponse> CreateCheckoutSessionAsync()
    {
        var url = await _billingService.CreateCheckoutSessionAsync(GetUserId());

        return new CheckoutSessionResponse { Url = url };
    }

    [HttpGet("CheckoutSession/{sessionId}/Status")]
    public async Task<CheckoutSessionStatusResponse> GetCheckoutSessionStatusAsync(string sessionId)
    {
        var status = await _billingService.GetCheckoutSessionStatusAsync(GetUserId(), sessionId);

        return new CheckoutSessionStatusResponse { Status = status };
    }

    [HttpGet("Subscription")]
    public async Task<SubscriptionResponse> GetSubscriptionAsync()
    {
        return await _billingService.GetSubscriptionAsync(GetUserId());
    }

    [HttpPost("PortalSession")]
    public async Task<PortalSessionResponse> CreatePortalSessionAsync()
    {
        var url = await _billingService.CreatePortalSessionAsync(GetUserId());

        return new PortalSessionResponse { Url = url };
    }
}
