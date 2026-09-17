using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class StarPurchaseStatusResponse
{
    [JsonPropertyName("Status")]
    public StarPurchaseStatus Status { get; set; }
}
