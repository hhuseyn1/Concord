using System.IdentityModel.Tokens.Jwt;
using System.Text;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Settings;
using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace Concord.API.Configs;

public static class AuthConfig
{
    public static AuthenticationBuilder SetupAuth(this IServiceCollection services, AuthenticationSettings? settings)
    {
        if (string.IsNullOrWhiteSpace(settings?.Issuer))
            throw new MissingSettingException(nameof(AuthenticationSettings.Issuer));

        if (string.IsNullOrWhiteSpace(settings?.Audience))
            throw new MissingSettingException(nameof(AuthenticationSettings.Audience));

        if (string.IsNullOrWhiteSpace(settings?.SigningKey))
            throw new MissingSettingException(nameof(AuthenticationSettings.SigningKey));

        return services
         .AddAuthentication(options =>
         {
             options.DefaultAuthenticateScheme = "AuthScheme";
             options.DefaultChallengeScheme = "AuthScheme";
         })
         .AddJwtBearer("AuthScheme", options =>
         {
             options.MapInboundClaims = false;
             options.Events = new Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerEvents
             {
                 OnMessageReceived = context =>
                 {
                     var token = context.Request.Query["access_token"];
                     if (!string.IsNullOrEmpty(token) && context.Request.Path.StartsWithSegments("/hubs"))
                         context.Token = token;
                     return Task.CompletedTask;
                 },
                 OnTokenValidated = async context =>
                 {
                     var sidValue = context.Principal?.FindFirst(JwtRegisteredClaimNames.Sid)?.Value;

                     // No sid claim (e.g. legacy tokens in flight): do not fail.
                     if (string.IsNullOrEmpty(sidValue) || !Guid.TryParse(sidValue, out var sessionId))
                         return;

                     var db = context.HttpContext.RequestServices.GetRequiredService<ApplicationDbContext>();
                     var session = await db.Sessions.AsNoTracking()
                         .Where(session => session.Id == sessionId)
                         .Select(session => new { session.AccessTokenId })
                         .FirstOrDefaultAsync();

                     if (session is null)
                     {
                         // P2.14: security-relevant decision point - a request presenting an
                         // otherwise-valid access token for an already-revoked session.
                         var logger = context.HttpContext.RequestServices.GetRequiredService<ILoggerFactory>().CreateLogger("Concord.Auth");
                         logger.LogWarning("Rejected request: session {SessionId} no longer exists (revoked)", sessionId);
                         context.Fail("Session revoked");
                         return;
                     }

                     var jtiValue = context.Principal?.FindFirst(JwtRegisteredClaimNames.Jti)?.Value;

                     if (!Guid.TryParse(jtiValue, out var accessTokenId) || accessTokenId != session.AccessTokenId)
                     {
                         // The access token was superseded by a refresh (AccessTokenId rotated) but is
                         // still within its own natural lifetime - reject it so rotation is actually
                         // enforced rather than merely cosmetic.
                         var logger = context.HttpContext.RequestServices.GetRequiredService<ILoggerFactory>().CreateLogger("Concord.Auth");
                         logger.LogWarning("Rejected request: access token for session {SessionId} has been rotated out", sessionId);
                         context.Fail("Access token rotated");
                     }
                 }
             };
             options.TokenValidationParameters = new TokenValidationParameters
             {
                 ValidateIssuer = true,
                 ValidateAudience = true,
                 ValidateLifetime = true,
                 ClockSkew = TimeSpan.Zero,
                 ValidateIssuerSigningKey = true,
                 ValidIssuer = settings.Issuer,
                 ValidAudience = settings.Audience,
                 IssuerSigningKey = new SymmetricSecurityKey(
                     Encoding.UTF8.GetBytes(settings.SigningKey)
                 ),
                 NameClaimType = JwtRegisteredClaimNames.Sub,
                 RoleClaimType = "role"
             };
         });
    }

    public static IApplicationBuilder EnableAuth(this IApplicationBuilder app)
    {
        app.UseAuthentication();
        app.UseAuthorization();

        return app;
    }
}