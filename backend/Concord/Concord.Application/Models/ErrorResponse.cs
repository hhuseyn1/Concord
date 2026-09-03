using System.Text.Json.Serialization;

namespace Concord.Application.Models;

public class ErrorResponse
{
    public ErrorResponse()
    {
        Message = null!;
    }

    public ErrorResponse(string message)
    {
        Message = message;
    }

    [JsonPropertyName("Message")]
    public string Message { get; set; }
}