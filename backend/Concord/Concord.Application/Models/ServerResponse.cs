using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ServerResponse
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("Name")]
    public string? Name { get; set; }

    [JsonPropertyName("OwnerId")]
    public Guid OwnerId { get; set; }

    [JsonPropertyName("IconUrl")]
    public string? IconUrl { get; set; }

    [JsonPropertyName("Created")]
    public DateTime Created { get; set; }

    /// <summary>
    /// Only meaningful on the response from joining by invite code: true if this call actually
    /// created the membership, false if the caller was already a member and the join was a no-op.
    /// Always false elsewhere (e.g. GET /Servers) since it doesn't apply there.
    /// </summary>
    [JsonPropertyName("JoinedNow")]
    public bool JoinedNow { get; set; }
}
