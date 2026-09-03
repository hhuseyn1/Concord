namespace Concord.Application.Enums;

/// <summary>Discriminates a <see cref="Concord.Application.Models.GlobalSearchResultResponse"/> row
/// (P2.3) - a global search result can come from either a channel or a DM conversation, which are
/// otherwise unrelated tables.</summary>
public enum MessageSourceType
{
    Channel,
    DirectMessage
}
