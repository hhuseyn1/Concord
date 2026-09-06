using Concord.API.Configs;
using Concord.API.HealthChecks;
using Concord.API.Hubs;
using Concord.API.Middlewares;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Services;
using Concord.Infrastructure.Settings;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json.Converters;
using Newtonsoft.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

if (builder.Environment.IsProduction())
    builder.AddKeyVault();

builder.Services.Configure<AuthenticationSettings>(builder.Configuration.GetSection(nameof(AuthenticationSettings)));
builder.Services.Configure<ApiSettings>(builder.Configuration.GetSection(nameof(ApiSettings)));
builder.Services.Configure<LiveKitSettings>(builder.Configuration.GetSection(nameof(LiveKitSettings)));
builder.Services.Configure<EmailSettings>(builder.Configuration.GetSection(nameof(EmailSettings)));
builder.Services.Configure<BlobStorageSettings>(builder.Configuration.GetSection(nameof(BlobStorageSettings)));

var authSettings = builder.Configuration.GetSection(nameof(AuthenticationSettings)).Get<AuthenticationSettings>();

builder.AddSerilogLogging();

builder.Services.AddControllers()
    .SetupCustomModelValidationResponse()
    .AddNewtonsoftJson(options =>
    {
        options.SerializerSettings.ContractResolver = new DefaultContractResolver();
        options.SerializerSettings.Converters.Add(new StringEnumConverter());
    });
builder.Services.AddEndpointsApiExplorer();

builder.Services.AddHttpContextAccessor();
builder.Services.AddInfrastructureServices();
builder.Services.AddRealtimeNotifiers();
builder.Services.AddHostedService<CleanupBackgroundService>();

builder.Services.AddDataProtection()
    .SetApplicationName("Concord")
    .PersistKeysToFileSystem(new DirectoryInfo(Path.Combine(builder.Environment.ContentRootPath, "keys")));

builder.Services.AddHealthChecks()
    .AddCheck<DatabaseHealthCheck>("database", tags: ["ready"]);
builder.Services.AddTransient<GlobalExceptionHandlingMiddleware>();
builder.Services.AddTransient<CorrelationIdMiddleware>();

builder.Services.AddDatabase(builder.Configuration);
builder.Services.AddSignalRWithRedisBackplane(builder.Configuration);
builder.Services.AddPresenceRedis(builder.Configuration);
builder.Services.AddLiveKit(builder.Configuration);
builder.Services.AddFileStorage(builder.Configuration, builder.Environment.IsProduction());

builder.Services.SetupAuth(authSettings);
builder.Services.SetupCorsPolicy(builder.Configuration, builder.Environment.IsDevelopment());

builder.Services.AddRateLimitingServices(builder.Environment);

if (builder.Environment.IsDevelopment())
    builder.Services.AddJwtSwagger(builder.Environment.ApplicationName);

var app = builder.Build();

if (!app.Environment.IsProduction())
    Directory.CreateDirectory(Path.Combine(app.Environment.WebRootPath, "uploads"));

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
    app.UseHsts();
}

app.UseStaticFiles(new StaticFileOptions
{
    OnPrepareResponse = context =>
        context.Context.Response.Headers.Append("X-Content-Type-Options", "nosniff")
});
app.EnableCorsPolicy();
app.UseMiddleware<CorrelationIdMiddleware>();
app.UseMiddleware<GlobalExceptionHandlingMiddleware>();
app.EnableAuth();
app.UseRateLimiter();

if (app.Environment.IsDevelopment())
    app.UseSwaggerWithUI();

using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

    await context.Database.MigrateAsync();

    if (app.Environment.IsDevelopment())
        await DbSeeder.SeedAsync(context);
}

app.MapHealthChecks("/health/live", new HealthCheckOptions { Predicate = _ => false });
app.MapHealthChecks("/health/ready", new HealthCheckOptions { Predicate = check => check.Tags.Contains("ready") });

app.MapControllers();
app.MapHub<MessagesHub>("/hubs/messages");
app.MapHub<PresenceHub>("/hubs/presence");
app.MapHub<NotificationsHub>("/hubs/notifications");
app.MapHub<VoiceHub>("/hubs/voice");
app.MapHub<DirectMessagesHub>("/hubs/direct-messages");
app.MapHub<ServersHub>("/hubs/servers");

app.Run();