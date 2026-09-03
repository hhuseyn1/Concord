namespace Concord.Application.Enums;

/// <summary>What kind of activity a Desktop Presence Agent (P2.8) reported - see
/// docs/DESKTOP_AGENT_PROTOCOL.md for the ingestion contract.</summary>
public enum ActivityType
{
    Playing,
    Listening,
    Coding,
    Using
}
