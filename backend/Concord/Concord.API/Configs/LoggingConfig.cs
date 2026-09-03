using Concord.Domain.Exceptions;
using Concord.Infrastructure.Settings;
using Elastic.Ingest.Elasticsearch.DataStreams;
using Elastic.Serilog.Sinks;
using Serilog;

namespace Concord.API.Configs;

public static class LoggingConfig
{
    public static WebApplicationBuilder AddSerilogLogging(this WebApplicationBuilder builder)
    {
        var appSettings = builder.Configuration.GetSection(nameof(ApiSettings)).Get<ApiSettings>();

        if (string.IsNullOrWhiteSpace(appSettings?.ElasticsearchBaseAddress))
            throw new MissingSettingException(nameof(appSettings.ElasticsearchBaseAddress));

        Log.Logger = new LoggerConfiguration()
            .Enrich.FromLogContext()
            .WriteTo.Console()
            .WriteTo.Elasticsearch([new Uri(appSettings.ElasticsearchBaseAddress)],
                options => options.DataStream = new DataStreamName("logs", builder.Environment.ApplicationName,
                    builder.Environment.EnvironmentName))
            .CreateLogger();

        builder.Services.AddSerilog();

        return builder;
    }
}
