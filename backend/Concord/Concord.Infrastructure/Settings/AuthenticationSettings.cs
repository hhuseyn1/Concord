namespace Concord.Infrastructure.Settings;

public class AuthenticationSettings
{
    public string Issuer { get; set; } = null!;
    public string Audience { get; set; } = null!;
    public string SigningKey { get; set; } = null!;
    public int AccessTokenExpiresInMinutes { get; set; }
    public int RefreshTokenExpiresInDays { get; set; }
    public int NonPersistentSessionExpiresInHours { get; set; }
}