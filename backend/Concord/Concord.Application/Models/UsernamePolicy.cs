using System.Text.RegularExpressions;

namespace Concord.Application.Models;

public static class UsernamePolicy
{
    public static readonly Regex Pattern = new("^[a-zA-Z0-9_]{1,32}$");

    public static bool IsValid(string? username) => username is not null && Pattern.IsMatch(username);
}
