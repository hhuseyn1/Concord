using System.Text.Json.Serialization;
using Concord.Application.Enums;

namespace Concord.Application.Models;

public class StartCallRequest
{
    [JsonPropertyName("Type")]
    public CallType Type { get; set; }
}
