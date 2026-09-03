namespace Concord.API.Configs;

public static class CorsConfig
{
    public static IServiceCollection SetupCorsPolicy(
        this IServiceCollection services,
        IConfiguration configuration,
        bool isDevelopment)
    {
        services.AddCors(options =>
            options.AddPolicy("Public", policy =>
            {
                if (isDevelopment)
                {
                    policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
                }
                else
                {
                    var origins = configuration.GetSection("ApiSettings:AllowedOrigins").Get<string[]>() ?? [];
                    policy.WithOrigins(origins).AllowAnyHeader().AllowAnyMethod();
                }
            }));

        return services;
    }

    public static IApplicationBuilder EnableCorsPolicy(this IApplicationBuilder app)
    {
        app.UseCors("Public");
        return app;
    }
}   