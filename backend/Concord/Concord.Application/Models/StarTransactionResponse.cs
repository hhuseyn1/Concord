using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class StarTransactionResponse
{
    [JsonPropertyName("Id")]
    public Guid Id { get; set; }

    [JsonPropertyName("Type")]
    public StarTransactionType Type { get; set; }

    [JsonPropertyName("Amount")]
    public int Amount { get; set; }

    [JsonPropertyName("BalanceAfter")]
    public int BalanceAfter { get; set; }

    /// <summary>Resolved server-side - null unless this row is a TransferSent/TransferReceived.</summary>
    [JsonPropertyName("CounterpartyUsername")]
    public string? CounterpartyUsername { get; set; }

    [JsonPropertyName("Created")]
    public DateTime Created { get; set; }
}
