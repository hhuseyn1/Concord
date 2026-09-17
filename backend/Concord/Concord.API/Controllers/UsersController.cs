using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0/Users")]
[Authorize]
public class UsersController(UsersService usersService, PushTokensService pushTokensService) : BaseApiController
{
    private readonly UsersService _usersService = usersService;
    private readonly PushTokensService _pushTokensService = pushTokensService;

    [HttpGet("Me")]
    public async Task<MyProfileResponse> GetMyProfileAsync()
    {
        return await _usersService.GetMyProfileAsync(GetUserId());
    }

    [HttpPut("Me")]
    public async Task<MyProfileResponse> UpdateMyProfileAsync(UpdateProfileRequest request)
    {
        return await _usersService.UpdateMyProfileAsync(GetUserId(), request);
    }

    [HttpPut("Me/Preferences")]
    public async Task<MyProfileResponse> UpdateMyPreferencesAsync(UpdatePreferencesRequest request)
    {
        return await _usersService.UpdateMyPreferencesAsync(GetUserId(), request);
    }

    [HttpPut("Me/Privacy")]
    public async Task<MyProfileResponse> UpdateMyPrivacyAsync(UpdatePrivacyRequest request)
    {
        return await _usersService.UpdateMyPrivacyAsync(GetUserId(), request);
    }

    [HttpPut("Me/CustomStatus")]
    public async Task<MyProfileResponse> UpdateMyCustomStatusAsync(UpdateCustomStatusRequest request)
    {
        return await _usersService.UpdateMyCustomStatusAsync(GetUserId(), request);
    }

    [HttpPut("Me/Activity")]
    public async Task<MyProfileResponse> UpdateMyActivityAsync(UpdateActivityRequest request)
    {
        return await _usersService.UpdateMyActivityAsync(GetUserId(), request);
    }

    [HttpGet("{userId:guid}")]
    public async Task<PublicProfileResponse> GetPublicProfileAsync(Guid userId)
    {
        return await _usersService.GetPublicProfileAsync(GetUserId(), userId);
    }

    [HttpGet("Search")]
    public async Task<List<PublicProfileResponse>> SearchByUsernameAsync(string query)
    {
        return await _usersService.SearchByUsernameAsync(GetUserId(), query);
    }

    [HttpDelete("Me")]
    public async Task DeleteMyAccountAsync(DeleteAccountRequest request)
    {
        await _usersService.RequestAccountDeletionAsync(GetUserId(), request);
    }

    [HttpPost("Me/PushTokens")]
    public async Task RegisterPushTokenAsync(RegisterPushTokenRequest request)
    {
        await _pushTokensService.RegisterAsync(GetUserId(), request);
    }

    [HttpDelete("Me/PushTokens/{token}")]
    public async Task DeregisterPushTokenAsync(string token)
    {
        await _pushTokensService.DeregisterAsync(GetUserId(), token);
    }
}
