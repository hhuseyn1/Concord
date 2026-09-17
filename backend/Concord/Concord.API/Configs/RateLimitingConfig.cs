using System.Threading.RateLimiting;

namespace Concord.API.Configs;

public static class RateLimitingConfig
{
    public static IServiceCollection AddRateLimitingServices(this IServiceCollection services, IWebHostEnvironment environment)
    {
        services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

            if (environment.IsDevelopment())
            {
                options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(_ => RateLimitPartition.GetNoLimiter("dev"));
                return;
            }

            options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
            {
                var routeKey = GetRouteKey(httpContext);

                return routeKey switch
                {
                    "POST Api/V1.0/Login" or "POST Api/V1.0/Login/TwoFactor" =>
                        RateLimitPartition.GetFixedWindowLimiter(
                            $"login:{GetClientIp(httpContext)}",
                            _ => new FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

                    "POST Api/V1.0/Register" =>
                        RateLimitPartition.GetFixedWindowLimiter(
                            $"register:{GetClientIp(httpContext)}",
                            _ => new FixedWindowRateLimiterOptions { PermitLimit = 5, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

                    "POST Api/V1.0/Forgot-password" =>
                        RateLimitPartition.GetFixedWindowLimiter(
                            $"forgot-password:{GetClientIp(httpContext)}",
                            _ => new FixedWindowRateLimiterOptions { PermitLimit = 5, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

                    "POST Api/V1.0/Resend-verification-email" =>
                        RateLimitPartition.GetFixedWindowLimiter(
                            $"resend-verification:{GetClientIp(httpContext)}",
                            _ => new FixedWindowRateLimiterOptions { PermitLimit = 5, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

                    "POST Api/V1.0/Reset-password" =>
                        RateLimitPartition.GetFixedWindowLimiter(
                            $"reset-password:{GetClientIp(httpContext)}",
                            _ => new FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

                    "POST Api/V1.0/Verify-email" =>
                        RateLimitPartition.GetFixedWindowLimiter(
                            $"verify-email:{GetClientIp(httpContext)}",
                            _ => new FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

                    "POST Api/V1.0/Me:Change-password" or
                    "POST Api/V1.0/Me/TwoFactor/Setup" or
                    "POST Api/V1.0/Me/TwoFactor/Enable" or
                    "POST Api/V1.0/Me/TwoFactor/Disable" or
                    "POST Api/V1.0/Me/TwoFactor/Recovery-Codes" =>
                        RateLimitPartition.GetFixedWindowLimiter(
                            $"change-password:{GetUserOrIp(httpContext)}",
                            _ => new FixedWindowRateLimiterOptions { PermitLimit = 5, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

                    "POST Api/V1.0/Servers/{serverId:guid}/Channels/{channelId:guid}/Messages" or
                    "POST Api/V1.0/DirectMessages/Conversations/{conversationId:guid}/Messages" =>
                        RateLimitPartition.GetFixedWindowLimiter(
                            $"send-message:{GetUserOrIp(httpContext)}",
                            _ => new FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromSeconds(10), QueueLimit = 0 }),

                    "POST Api/V1.0/Friends/Requests/{targetUserId:guid}" =>
                        RateLimitPartition.GetFixedWindowLimiter(
                            $"friend-request:{GetUserOrIp(httpContext)}",
                            _ => new FixedWindowRateLimiterOptions { PermitLimit = 20, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

                    "GET Api/V1.0/Search/Messages" =>
                        RateLimitPartition.GetFixedWindowLimiter(
                            $"search:{GetUserOrIp(httpContext)}",
                            _ => new FixedWindowRateLimiterOptions { PermitLimit = 20, Window = TimeSpan.FromSeconds(10), QueueLimit = 0 }),

                    "POST Api/V1.0/Files/Avatar" or
                    "POST Api/V1.0/Files/ServerIcon" or
                    "POST Api/V1.0/Files/Attachment" =>
                        RateLimitPartition.GetFixedWindowLimiter(
                            $"file-upload:{GetUserOrIp(httpContext)}",
                            _ => new FixedWindowRateLimiterOptions { PermitLimit = 20, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

                    "POST Api/V1.0/QrLogin/Sessions" or
                    "GET Api/V1.0/QrLogin/Sessions/Status" or
                    "GET Api/V1.0/QrLogin/Requests/{userCode}" or
                    "POST Api/V1.0/QrLogin/Requests/{userCode}/Approve" or
                    "POST Api/V1.0/QrLogin/Requests/{userCode}/Deny" =>
                        RateLimitPartition.GetFixedWindowLimiter(
                            $"qr-login:{GetUserOrIp(httpContext)}",
                            _ => new FixedWindowRateLimiterOptions { PermitLimit = 90, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

                    "POST Api/V1.0/Voice/Webhook" =>
                        RateLimitPartition.GetFixedWindowLimiter(
                            $"voice-webhook:{GetClientIp(httpContext)}",
                            _ => new FixedWindowRateLimiterOptions { PermitLimit = 120, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }),

                    _ => RateLimitPartition.GetNoLimiter("none")
                };
            });
        });

        return services;
    }

    private static string GetRouteKey(HttpContext httpContext)
    {
        var routePattern = (httpContext.GetEndpoint() as RouteEndpoint)?.RoutePattern.RawText;
        return routePattern is null ? string.Empty : $"{httpContext.Request.Method} {routePattern}";
    }

    private static string GetClientIp(HttpContext httpContext) =>
        httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";

    private static string GetUserOrIp(HttpContext httpContext) =>
        httpContext.User.Identity?.IsAuthenticated == true
            ? httpContext.User.FindFirst("sub")?.Value ?? GetClientIp(httpContext)
            : GetClientIp(httpContext);
}
