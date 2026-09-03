using System.Threading.RateLimiting;
using Concord.API.Configs;
using Concord.API.HealthChecks;
using Concord.API.Hubs;
using Concord.API.Middlewares;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Services;
using Concord.Infrastructure.Settings;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json.Converters;
using Newtonsoft.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

builder.Services.Configure<AuthenticationSettings>(builder.Configuration.GetSection(nameof(AuthenticationSettings)));
builder.Services.Configure<ApiSettings>(builder.Configuration.GetSection(nameof(ApiSettings)));
builder.Services.Configure<LiveKitSettings>(builder.Configuration.GetSection(nameof(LiveKitSettings)));
builder.Services.Configure<EmailSettings>(builder.Configuration.GetSection(nameof(EmailSettings)));
builder.Services.Configure<AzureBlobStorageSettings>(builder.Configuration.GetSection(nameof(AzureBlobStorageSettings)));

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

// Persisted to a volume-backed directory (see compose.yaml's backend-dataprotection-keys volume) so
// a container restart/redeploy does not rotate the key ring - that would silently break
// TwoFactorService's Protect/Unprotect for every already-enrolled user. SetApplicationName pins the
// purpose-string namespace so keys stay valid across redeploys that might otherwise change the
// default (assembly/path-derived) application discriminator.
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

// Rate limiting (consolidated here rather than split across a Configs file and per-controller
// [EnableRateLimiting] attributes): a single GlobalLimiter dispatches on "{METHOD} {route
// template}" so every limit - which endpoints get one, and what it is - is visible in one place
// without hunting through controllers. Endpoints not listed below are intentionally unthrottled,
// matching the pre-consolidation state where only the endpoints below ever carried a policy.
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    if (builder.Environment.IsDevelopment())
    {
        // Effectively a no-op in Development, mirroring how CorsConfig.SetupCorsPolicy branches on
        // isDevelopment so local testing isn't slowed down.
        options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(_ => RateLimitPartition.GetNoLimiter("dev"));
        return;
    }

    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
    {
        var routeKey = GetRouteKey(httpContext);

        return routeKey switch
        {
            // Login: unauthenticated + credential stuffing target, so partition by client IP.
            "POST Api/V1.0/Login" or "POST Api/V1.0/Login/TwoFactor" =>
                RateLimitPartition.GetFixedWindowLimiter(
                    $"login:{GetClientIp(httpContext)}",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

            // Register: unauthenticated, same mass-account-creation concern as Login - partition by IP.
            "POST Api/V1.0/Register" =>
                RateLimitPartition.GetFixedWindowLimiter(
                    $"register:{GetClientIp(httpContext)}",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = 5, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

            // ForgotPassword: unauthenticated, same concern as Login/Register (also a vector for
            // spamming a victim's inbox with reset emails) - partition by IP.
            "POST Api/V1.0/Forgot-password" =>
                RateLimitPartition.GetFixedWindowLimiter(
                    $"forgot-password:{GetClientIp(httpContext)}",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = 5, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

            // ResetPassword: unauthenticated - bounds brute-forcing the reset token itself.
            "POST Api/V1.0/Reset-password" =>
                RateLimitPartition.GetFixedWindowLimiter(
                    $"reset-password:{GetClientIp(httpContext)}",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

            // VerifyEmail: unauthenticated - same concern as Reset-password, bounds brute-forcing the
            // verification token itself.
            "POST Api/V1.0/Verify-email" =>
                RateLimitPartition.GetFixedWindowLimiter(
                    $"verify-email:{GetClientIp(httpContext)}",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

            // ChangePassword + every 2FA management action: authenticated but still worth bounding -
            // each either re-checks the current password server-side or is equally security-sensitive,
            // so an attacker with a live session could otherwise brute-force it.
            "POST Api/V1.0/Me:Change-password" or
            "POST Api/V1.0/Me/TwoFactor/Setup" or
            "POST Api/V1.0/Me/TwoFactor/Enable" or
            "POST Api/V1.0/Me/TwoFactor/Disable" or
            "POST Api/V1.0/Me/TwoFactor/Recovery-Codes" =>
                RateLimitPartition.GetFixedWindowLimiter(
                    $"change-password:{GetUserOrIp(httpContext)}",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = 5, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

            // SendMessage: authenticated, partition per user so one account spamming doesn't consume
            // other users' quota. Compounds with the Content length cap.
            "POST Api/V1.0/Servers/{serverId:guid}/Channels/{channelId:guid}/Messages" or
            "POST Api/V1.0/DirectMessages/Conversations/{conversationId:guid}/Messages" =>
                RateLimitPartition.GetFixedWindowLimiter(
                    $"send-message:{GetUserOrIp(httpContext)}",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromSeconds(10), QueueLimit = 0 }),

            // FriendRequest: authenticated - bounds mass-request spam toward other users.
            "POST Api/V1.0/Friends/Requests/{targetUserId:guid}" =>
                RateLimitPartition.GetFixedWindowLimiter(
                    $"friend-request:{GetUserOrIp(httpContext)}",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = 20, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

            // Search: authenticated - ILIKE/trigram queries are more expensive than a typical read, so
            // this is tighter than most authenticated policies despite being read-only.
            "GET Api/V1.0/Search/Messages" =>
                RateLimitPartition.GetFixedWindowLimiter(
                    $"search:{GetUserOrIp(httpContext)}",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = 20, Window = TimeSpan.FromSeconds(10), QueueLimit = 0 }),

            // FileUpload: authenticated - bounds storage/bandwidth abuse from a single account.
            "POST Api/V1.0/Files/Avatar" or
            "POST Api/V1.0/Files/ServerIcon" or
            "POST Api/V1.0/Files/Attachment" =>
                RateLimitPartition.GetFixedWindowLimiter(
                    $"file-upload:{GetUserOrIp(httpContext)}",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = 20, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

            // QrLogin: partly unauthenticated, so partitioned by user-or-IP together. The limit has to
            // absorb genuine polling - a browser polls roughly every 2s for up to 2 minutes, so ~60
            // calls per attempt - while still bounding someone grinding user codes against the approve
            // endpoint. Codes are 8 characters from a 32-character alphabet and live 2 minutes, so even
            // at this ceiling a guessing attack is not viable.
            "POST Api/V1.0/QrLogin/Sessions" or
            "GET Api/V1.0/QrLogin/Sessions/Status" or
            "GET Api/V1.0/QrLogin/Requests/{userCode}" or
            "POST Api/V1.0/QrLogin/Requests/{userCode}/Approve" or
            "POST Api/V1.0/QrLogin/Requests/{userCode}/Deny" =>
                RateLimitPartition.GetFixedWindowLimiter(
                    $"qr-login:{GetUserOrIp(httpContext)}",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = 90, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

            // VoiceWebhook: unauthenticated (trust comes from the signature check in VoiceService),
            // called by LiveKit itself rather than end users, so the limit is generous but still bounds
            // a misbehaving/compromised LiveKit deployment.
            "POST Api/V1.0/Voice/Webhook" =>
                RateLimitPartition.GetFixedWindowLimiter(
                    $"voice-webhook:{GetClientIp(httpContext)}",
                    _ => new FixedWindowRateLimiterOptions { PermitLimit = 120, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

            _ => RateLimitPartition.GetNoLimiter("none")
        };
    });
});

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
    // P2.14 pentest finding: uploaded files are served purely by extension-derived Content-Type
    // with no verification the bytes actually match it - nosniff stops a browser from ever
    // second-guessing that header via content sniffing regardless.
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

static string GetRouteKey(HttpContext httpContext)
{
    var routePattern = (httpContext.GetEndpoint() as RouteEndpoint)?.RoutePattern.RawText;
    return routePattern is null ? string.Empty : $"{httpContext.Request.Method} {routePattern}";
}

static string GetClientIp(HttpContext httpContext) =>
    httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";

static string GetUserOrIp(HttpContext httpContext) =>
    httpContext.User.Identity?.IsAuthenticated == true
        ? httpContext.User.FindFirst("sub")?.Value ?? GetClientIp(httpContext)
        : GetClientIp(httpContext);