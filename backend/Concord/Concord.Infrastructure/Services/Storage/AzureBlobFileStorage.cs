using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

namespace Concord.Infrastructure.Services.Storage;

/// <summary>Saves to an Azure Blob Storage container. Used only in Production (see <c>FileStorageConfig</c>).</summary>
public class AzureBlobFileStorage(BlobContainerClient containerClient) : IFileStorage
{
    private readonly BlobContainerClient _containerClient = containerClient;

    public async Task<string> SaveAsync(Stream content, string purposeSegment, string fileName, string contentType)
    {
        var blobClient = _containerClient.GetBlobClient($"{purposeSegment}/{fileName}");

        await blobClient.UploadAsync(content, new BlobHttpHeaders { ContentType = contentType });

        return blobClient.Uri.ToString();
    }

    public bool OwnsUrl(string? url) =>
        !string.IsNullOrWhiteSpace(url) && url.StartsWith(_containerClient.Uri.ToString(), StringComparison.OrdinalIgnoreCase);

    public async Task DeleteAsync(string url)
    {
        if (!OwnsUrl(url))
            return;

        var blobName = url[(_containerClient.Uri.ToString().Length + 1)..];

        try
        {
            await _containerClient.GetBlobClient(blobName).DeleteIfExistsAsync();
        }
        catch
        {
        }
    }
}
