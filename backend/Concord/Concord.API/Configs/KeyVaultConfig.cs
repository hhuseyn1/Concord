using Azure.Identity;
using Concord.Domain.Exceptions;

namespace Concord.API.Configs;

public static class KeyVaultConfig
{
    /// <summary>
    /// Layers Azure Key Vault on top of the existing configuration sources, so every setting bound
    /// from appsettings/.env (connection strings, signing keys, SMTP/LiveKit/Blob credentials, ...)
    /// is instead resolved from the vault in Production. Secret names use '--' where the equivalent
    /// config key uses ':' (e.g. AuthenticationSettings--SigningKey for AuthenticationSettings:SigningKey)
    /// since Key Vault secret names can't contain ':' - the provider maps that back automatically.
    /// </summary>
    public static WebApplicationBuilder AddKeyVault(this WebApplicationBuilder builder)
    {
        var vaultUri = builder.Configuration["KeyVaultSettings:Uri"];

        if (string.IsNullOrWhiteSpace(vaultUri))
            throw new MissingSettingException("KeyVaultSettings:Uri");

        builder.Configuration.AddAzureKeyVault(new Uri(vaultUri), new DefaultAzureCredential());

        return builder;
    }
}
