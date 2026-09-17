namespace Concord.Infrastructure.Services.Storage;

public interface IFileStorage
{
    Task<string> SaveAsync(Stream content, string purposeSegment, string fileName, string contentType);

    bool OwnsUrl(string? url);

    Task DeleteAsync(string url);
}
