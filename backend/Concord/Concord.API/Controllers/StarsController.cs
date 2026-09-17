using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;

[Route("Api/V1.0/Stars")]
[Authorize]
public class StarsController(StarsService starsService) : BaseApiController
{
    private readonly StarsService _starsService = starsService;

    [HttpGet("Config")]
    public StarsConfigResponse GetConfig()
    {
        return StarsService.GetConfig();
    }

    [HttpGet("Wallet")]
    public async Task<StarWalletResponse> GetWalletAsync()
    {
        return await _starsService.GetWalletAsync(GetUserId());
    }

    [HttpGet("Transactions")]
    public async Task<PagedResult<StarTransactionResponse>> GetTransactionsAsync([FromQuery] int page, [FromQuery] int pageSize)
    {
        return await _starsService.GetTransactionsAsync(GetUserId(), page, pageSize);
    }

    [HttpPost("Transfer")]
    public async Task<TransferStarsResponse> TransferAsync([FromBody] TransferStarsRequest request)
    {
        return await _starsService.TransferAsync(GetUserId(), request);
    }

    [HttpPost("PremiumTrial/Activate")]
    public async Task<ActivatePremiumTrialResponse> ActivatePremiumTrialAsync([FromBody] ActivatePremiumTrialRequest request)
    {
        return await _starsService.ActivatePremiumTrialAsync(GetUserId(), request);
    }

    [HttpPost("Purchases/CheckoutSession")]
    public async Task<CreateStarsCheckoutSessionResponse> CreateCheckoutSessionAsync([FromBody] CreateStarsCheckoutSessionRequest request)
    {
        return await _starsService.CreateCheckoutSessionAsync(GetUserId(), request.PackageId);
    }

    [HttpGet("Purchases/{purchaseId:guid}/Status")]
    public async Task<StarPurchaseStatusResponse> GetPurchaseStatusAsync(Guid purchaseId)
    {
        var status = await _starsService.GetPurchaseStatusAsync(GetUserId(), purchaseId);

        return new StarPurchaseStatusResponse { Status = status };
    }
}
