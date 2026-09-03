using System.IdentityModel.Tokens.Jwt;
using Concord.Domain.Enums;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[ApiController]
public class BaseApiController : ControllerBase
{
    [NonAction]
    protected Guid GetUserId()
    {
        var claimedUserId = User.Claims.FirstOrDefault(claim => claim.Type == JwtRegisteredClaimNames.Sub)?.Value;

        return Guid.TryParse(claimedUserId, out Guid userId) ? userId : throw new UnauthorizedAccessException();
    }

    [NonAction]
    protected Roles GetUserRole()
    {
        var claimedUserRole = User.Claims.FirstOrDefault(claim => claim.Type == "role")?.Value;

        return Enum.TryParse(claimedUserRole, out Roles userRole) ? userRole : throw new UnauthorizedAccessException();
    }

    [NonAction]
    protected string GetUserLocale()
    {
        var claimedUserLocale = User.Claims.FirstOrDefault(claim => claim.Type == JwtRegisteredClaimNames.Locale)?.Value;

        return string.IsNullOrWhiteSpace(claimedUserLocale) ? throw new UnauthorizedAccessException() : claimedUserLocale;
    }

    [NonAction]
    protected Guid GetSessionId()
    {
        var claimedSessionId = User.Claims.FirstOrDefault(claim => claim.Type == JwtRegisteredClaimNames.Sid)?.Value;

        return Guid.TryParse(claimedSessionId, out Guid sessionId) ? sessionId : throw new UnauthorizedAccessException();
    }
}