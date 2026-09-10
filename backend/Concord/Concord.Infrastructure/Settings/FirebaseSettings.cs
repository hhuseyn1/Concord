namespace Concord.Infrastructure.Settings;

public class FirebaseSettings
{
    /// <summary>
    /// The full contents of the Firebase service-account key (Project Settings -&gt; Service Accounts
    /// -&gt; Generate new private key), not a file path - production sets this from a secret
    /// (Key Vault/App Service configuration, same mechanism as <see cref="EmailSettings"/>) rather
    /// than expecting a JSON file to exist on the container's filesystem. Left empty in local/dev
    /// config on purpose: <c>ServicesConfig</c> falls back to <c>NoOpPushNotificationSender</c>
    /// whenever this is unset, rather than failing startup for an optional feature.
    /// </summary>
    public string? ServiceAccountJson { get; set; }
}
