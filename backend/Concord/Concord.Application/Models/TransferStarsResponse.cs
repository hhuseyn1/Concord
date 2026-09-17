using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class TransferStarsResponse
{
    [JsonPropertyName("Balance")]
    public int Balance { get; set; }
}
