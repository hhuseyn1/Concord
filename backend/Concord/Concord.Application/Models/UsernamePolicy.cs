using System.Text.RegularExpressions;

namespace Concord.Application.Models;

/// <summary>
/// Shared between registration (<c>AuthenticationService.RegisterAsync</c>) and profile edits
/// (<c>UsersService.UpdateMyProfileAsync</c>) so both enforce the exact same rule - a username valid
/// at signup must stay valid to keep, and vice versa.
/// </summary>
public static class UsernamePolicy
{
    public static readonly Regex Pattern = new("^[a-zA-Z0-9_]{1,32}$");

    public static bool IsValid(string? username) => username is not null && Pattern.IsMatch(username);
}
