using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0/Search")]
[Authorize]
public class SearchController(GlobalSearchService globalSearchService) : BaseApiController
{
    private readonly GlobalSearchService _globalSearchService = globalSearchService;

    [HttpGet("Messages")]
    public async Task<PagedResult<GlobalSearchResultResponse>> SearchMessagesAsync([FromQuery] string query, [FromQuery] int page, [FromQuery] int pageSize)
    {
        return await _globalSearchService.SearchAsync(GetUserId(), query, page, pageSize);
    }
}
