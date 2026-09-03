using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Services.Storage;
using Concord.Infrastructure.Settings;

namespace Concord.API.Configs;

public static class FileStorageConfig
{
    /// <summary>
    /// Local disk everywhere except Production, where uploads instead go to Azure Blob Storage -
    /// a container's filesystem doesn't survive a redeploy, so local storage would silently lose
    /// every avatar/server-icon/attachment the next time the API container is rebuilt.
    /// </summary>
    public static IServiceCollection AddFileStorage(this IServiceCollection services, IConfiguration configuration, bool isProduction)
    {
        if (!isProduction)
        {
            services.AddScoped<IFileStorage, LocalFileStorage>();
            return services;
        }

        var settings = configuration.GetSection(nameof(AzureBlobStorageSettings)).Get<AzureBlobStorageSettings>();

        if (string.IsNullOrWhiteSpace(settings?.ConnectionString))
            throw new MissingSettingException(nameof(AzureBlobStorageSettings.ConnectionString));

        if (string.IsNullOrWhiteSpace(settings.ContainerName))
            throw new MissingSettingException(nameof(AzureBlobStorageSettings.ContainerName));

        var containerClient = new BlobContainerClient(settings.ConnectionString, settings.ContainerName);

        // Public read access so uploaded URLs stay directly linkable, matching how UseStaticFiles
        // serves the local /uploads folder with no auth check today.
        containerClient.CreateIfNotExists(PublicAccessType.Blob);

        services.AddSingleton(containerClient);
        services.AddScoped<IFileStorage, AzureBlobFileStorage>();

        return services;
    }
}
