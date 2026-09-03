using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.OpenApi;

namespace Concord.API.Configs;

public static class SwaggerConfig
{
    public static IServiceCollection AddJwtSwagger(this IServiceCollection services, string serviceName)
    {
        services.AddEndpointsApiExplorer();
        services.AddSwaggerGen(options =>
        {
            options.SwaggerDoc(
                    "v1",
                     new OpenApiInfo
                     {
                         Title = $"{serviceName} API",
                         Version = "v1",
                         Description = $"{serviceName} ASP.NET Core Web API",
                         License = new OpenApiLicense { Name = "Private use" },
                     }
            );

            options.AddSecurityDefinition(
                    JwtBearerDefaults.AuthenticationScheme,
                    new OpenApiSecurityScheme
                    {
                        In = ParameterLocation.Header,
                        Description = "Please use access token",
                        Name = "Authorization",
                        Type = SecuritySchemeType.Http,
                        Scheme = JwtBearerDefaults.AuthenticationScheme,
                        BearerFormat = "JWT"
                    }
            );

        });

        return services;
    }

    public static IApplicationBuilder UseSwaggerWithUI(this IApplicationBuilder app)
    {
        app.UseSwagger();
        app.UseSwaggerUI();
        return app;
    }
}
