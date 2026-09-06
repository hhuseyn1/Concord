using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Services.Storage;
using Concord.Infrastructure.Settings;

namespace Concord.API.Configs;

public static class FileStorageConfig
{
    public static IServiceCollection AddFileStorage(this IServiceCollection services, IConfiguration configuration, bool isProduction)
    {
        if (!isProduction)
        {
            services.AddScoped<IFileStorage, LocalFileStorage>();
            return services;
        }

        var settings = configuration.GetSection(nameof(BlobStorageSettings)).Get<BlobStorageSettings>();

        if (string.IsNullOrWhiteSpace(settings?.ConnectionString))
            throw new MissingSettingException(nameof(BlobStorageSettings.ConnectionString));

        if (string.IsNullOrWhiteSpace(settings.PublicContainerName))
            throw new MissingSettingException(nameof(BlobStorageSettings.PublicContainerName));

        var containerClient = new BlobContainerClient(settings.ConnectionString, settings.PublicContainerName);

        containerClient.CreateIfNotExists(PublicAccessType.Blob);

        services.AddSingleton(containerClient);
        services.AddScoped<IFileStorage, AzureBlobFileStorage>();

        return services;
    }
}
