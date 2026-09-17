using Concord.Application.Models;
using Concord.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Concord.API.Controllers;


[Route("Api/V1.0/Files")]
[Authorize]
public class FilesController(FilesService filesService) : BaseApiController
{
    private readonly FilesService _filesService = filesService;

    [HttpPost("Avatar")]
    public async Task<FileUploadResponse> UploadAvatarAsync(IFormFile file)
    {
        return await _filesService.UploadAvatarAsync(GetUserId(), file);
    }

    [HttpPost("ServerIcon")]
    public async Task<FileUploadResponse> UploadServerIconAsync(IFormFile file)
    {
        return await _filesService.UploadServerIconAsync(GetUserId(), file);
    }

    [HttpPost("Attachment")]
    public async Task<FileUploadResponse> UploadAttachmentAsync(IFormFile file)
    {
        return await _filesService.UploadAttachmentAsync(GetUserId(), file);
    }
}
