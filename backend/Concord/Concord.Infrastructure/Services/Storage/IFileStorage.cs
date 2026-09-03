namespace Concord.Infrastructure.Services.Storage;

/// <summary>
/// Where <c>FilesService</c> actually persists uploaded bytes. All the validation (size,
/// content-type allow-list, magic-byte signature) stays in <c>FilesService</c> - this only
/// covers the storage backend, swapped per environment (see <c>FileStorageConfig</c>).
/// </summary>
public interface IFileStorage
{
    Task<string> SaveAsync(Stream content, string purposeSegment, string fileName, string contentType);

    /// <summary>Does this URL look like something this backend saved (as opposed to a URL a client just made up)?</summary>
    bool OwnsUrl(string? url);

    Task DeleteAsync(string url);
}
