using Azure.Identity;

namespace Concord.API.Configs;

public static class KeyVaultConfig
{
    public static WebApplicationBuilder AddKeyVault(this WebApplicationBuilder builder)
    {
        if (!builder.Environment.IsProduction())
            return builder;

        var keyVaultUrl = builder.Configuration["KeyVaultSettings:Uri"];
        if (string.IsNullOrEmpty(keyVaultUrl))
            return builder;

        var credential = new ManagedIdentityCredential(ManagedIdentityId.SystemAssigned);
        builder.Configuration.AddAzureKeyVault(new Uri(keyVaultUrl), credential);

        return builder;
    }
}


