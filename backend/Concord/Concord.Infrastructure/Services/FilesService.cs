using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Services.Storage;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

public class FilesService(IFileStorage fileStorage, ApplicationDbContext context)
{
    private const string AvatarPurpose = "avatars";
    private const string ServerIconPurpose = "server-icons";
    private const string AttachmentPurpose = "attachments";

    private const long ImageMaxSizeBytes = 5 * 1024 * 1024;
    private const long AttachmentMaxSizeBytes = 25 * 1024 * 1024;

    private static readonly string[] ImageContentTypes =
    [
        "image/png",
        "image/jpeg",
        "image/webp",
        "image/gif"
    ];

    private static readonly string[] AttachmentContentTypes =
    [
        .. ImageContentTypes,
        "video/mp4",
        "audio/mpeg",
        "audio/ogg",
        "application/pdf",
        "text/plain",
        "application/zip"
    ];

    private static readonly Dictionary<string, string[]> ExtensionsByContentType = new()
    {
        ["image/png"] = [".png"],
        ["image/jpeg"] = [".jpg", ".jpeg"],
        ["image/webp"] = [".webp"],
        ["image/gif"] = [".gif"],
        ["video/mp4"] = [".mp4"],
        ["audio/mpeg"] = [".mp3"],
        ["audio/ogg"] = [".ogg"],
        ["application/pdf"] = [".pdf"],
        ["text/plain"] = [".txt"],
        ["application/zip"] = [".zip"]
    };

    private static readonly Dictionary<string, Func<byte[], bool>> SignatureValidators = new()
    {
        ["image/png"] = bytes => StartsWith(bytes, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
        ["image/jpeg"] = bytes => StartsWith(bytes, [0xFF, 0xD8, 0xFF]),
        ["image/gif"] = bytes => StartsWith(bytes, "GIF87a"u8.ToArray()) || StartsWith(bytes, "GIF89a"u8.ToArray()),
        ["image/webp"] = bytes => bytes.Length >= 12 && StartsWith(bytes, "RIFF"u8.ToArray()) && bytes.AsSpan(8, 4).SequenceEqual("WEBP"u8),
        ["video/mp4"] = bytes => bytes.Length >= 8 && bytes.AsSpan(4, 4).SequenceEqual("ftyp"u8),
        ["audio/mpeg"] = bytes => StartsWith(bytes, "ID3"u8.ToArray()) || (bytes.Length >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0),
        ["audio/ogg"] = bytes => StartsWith(bytes, "OggS"u8.ToArray()),
        ["application/pdf"] = bytes => StartsWith(bytes, "%PDF-"u8.ToArray()),
        ["application/zip"] = bytes => StartsWith(bytes, [0x50, 0x4B, 0x03, 0x04]) || StartsWith(bytes, [0x50, 0x4B, 0x05, 0x06])
    };

    private static bool StartsWith(byte[] bytes, byte[] signature) =>
        bytes.Length >= signature.Length && bytes.AsSpan(0, signature.Length).SequenceEqual(signature);

    private readonly IFileStorage _fileStorage = fileStorage;
    private readonly ApplicationDbContext _context = context;

    public async Task<FileUploadResponse> UploadAvatarAsync(Guid uploaderUserId, IFormFile file)
    {
        var url = await SaveFileAsync(uploaderUserId, file, UploadPurpose.Avatar, AvatarPurpose, ImageContentTypes, ImageMaxSizeBytes);

        return new FileUploadResponse { Url = url };
    }

    public async Task<FileUploadResponse> UploadServerIconAsync(Guid uploaderUserId, IFormFile file)
    {
        var url = await SaveFileAsync(uploaderUserId, file, UploadPurpose.ServerIcon, ServerIconPurpose, ImageContentTypes, ImageMaxSizeBytes);

        return new FileUploadResponse { Url = url };
    }

    public async Task<FileUploadResponse> UploadAttachmentAsync(Guid uploaderUserId, IFormFile file)
    {
        var url = await SaveFileAsync(uploaderUserId, file, UploadPurpose.Attachment, AttachmentPurpose, AttachmentContentTypes, AttachmentMaxSizeBytes);

        return new FileUploadResponse { Url = url };
    }

    public bool IsOwnUploadUrl(string? url) => _fileStorage.OwnsUrl(url);

    public async Task<bool> IsOwnAttachmentAsync(Guid userId, string? url)
    {
        if (!IsOwnUploadUrl(url))
            return false;

        return await _context.UploadedFiles.AnyAsync(file =>
            file.Url == url && file.UploaderUserId == userId && file.Purpose == UploadPurpose.Attachment);
    }

    public async Task DeleteFileAsync(string? url)
    {
        if (string.IsNullOrWhiteSpace(url))
            return;

        await _fileStorage.DeleteAsync(url);
    }

    private async Task<string> SaveFileAsync(Guid uploaderUserId, IFormFile file, UploadPurpose purpose, string purposeSegment, string[] allowedContentTypes, long maxSizeBytes)
    {
        if (file is null || file.Length == 0)
            throw new ParameterValidationException(nameof(file));

        if (file.Length > maxSizeBytes)
            throw new FileTooLargeException(maxSizeBytes);

        if (!allowedContentTypes.Contains(file.ContentType) || !ExtensionsByContentType.TryGetValue(file.ContentType, out var allowedExtensions))
            throw new InvalidFileTypeException();

        var suppliedExtension = Path.GetExtension(file.FileName);

        if (!allowedExtensions.Contains(suppliedExtension, StringComparer.OrdinalIgnoreCase))
            throw new InvalidFileTypeException();

        if (SignatureValidators.TryGetValue(file.ContentType, out var isValidSignature))
        {
            var header = new byte[16];
            int bytesRead;

            await using (var stream = file.OpenReadStream())
            {
                bytesRead = await stream.ReadAsync(header.AsMemory(0, (int)Math.Min(header.Length, file.Length)));
            }

            if (bytesRead < header.Length)
                Array.Resize(ref header, bytesRead);

            if (!isValidSignature(header))
                throw new InvalidFileTypeException();
        }

        var extension = allowedExtensions[0];
        var fileName = $"{Guid.NewGuid()}{extension}";

        string url;

        await using (var stream = file.OpenReadStream())
        {
            url = await _fileStorage.SaveAsync(stream, purposeSegment, fileName, file.ContentType);
        }

        _context.UploadedFiles.Add(new UploadedFile
        {
            UploaderUserId = uploaderUserId,
            Url = url,
            Purpose = purpose
        });

        await _context.SaveChangesAsync();

        return url;
    }
}
