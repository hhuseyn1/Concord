namespace Concord.Infrastructure.Settings;

public class BlobStorageSettings
{
    public string ConnectionString { get; set; } = null!;
    public string PublicContainerName { get; set; } = null!;
    public string PrivateContainerName { get; set; } = null!;
}
