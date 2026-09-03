using Concord.Application.Models;
using Livekit.Server.Sdk.Dotnet;

namespace Concord.Infrastructure.Extensions;

public static class VoiceExtensions
{
    public static VoiceParticipantSummary MapToSummary(this ParticipantInfo participant) => new()
    {
        UserId = Guid.Parse(participant.Identity),
        Identity = participant.Identity,
        JoinedAt = DateTimeOffset.FromUnixTimeSeconds(participant.JoinedAt).UtcDateTime
    };
}
