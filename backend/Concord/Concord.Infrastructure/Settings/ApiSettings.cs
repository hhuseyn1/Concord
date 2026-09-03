namespace Concord.Infrastructure.Settings;

public class ApiSettings
{
    public string PostgresConnectionString { get; set; } = null!;
    public string ElasticsearchBaseAddress { get; set; } = null!;
    public string RedisConnectionString { get; set; } = null!;
    public string[] AllowedOrigins { get; set; } = [];
}
