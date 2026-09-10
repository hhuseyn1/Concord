/// Mirrors the backend's `Concord.Application.Models.UsernamePolicy` - kept in one place so the
/// registration form and the profile-edit form validate usernames identically.
final usernamePattern = RegExp(r'^[a-zA-Z0-9_]{1,32}$');
