using Microsoft.AspNetCore.Hosting;

namespace Concord.Infrastructure.Services.Storage;

public class LocalFileStorage(IWebHostEnvironment environment) : IFileStorage
{
    private const string UploadsUrlPrefix = "/uploads/";

    private readonly IWebHostEnvironment _environment = environment;

    public async Task<string> SaveAsync(Stream content, string purposeSegment, string fileName, string contentType)
    {
        var directoryPath = Path.Combine(_environment.WebRootPath, "uploads", purposeSegment);
        Directory.CreateDirectory(directoryPath);

        var fullPath = Path.Combine(directoryPath, fileName);

        await using (var stream = new FileStream(fullPath, FileMode.Create))
        {
            await content.CopyToAsync(stream);
        }

        return $"{UploadsUrlPrefix}{purposeSegment}/{fileName}";
    }

    public bool OwnsUrl(string? url) =>
        !string.IsNullOrWhiteSpace(url) && url.StartsWith(UploadsUrlPrefix, StringComparison.Ordinal);

    public Task DeleteAsync(string url)
    {
        try
        {
            var relativePath = url.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
            var fullPath = Path.Combine(_environment.WebRootPath, relativePath);

            if (File.Exists(fullPath))
                File.Delete(fullPath);
        }
        catch
        {
        }

        return Task.CompletedTask;
    }
}
