using Concord.Application.Enums;

namespace Concord.Domain.Entities;

/// <summary>
/// A database record of a disk artifact <c>FilesService</c> saved under
/// <c>wwwroot/uploads/{purpose}/</c>. Before this, an uploaded file had no row anywhere - it was
/// referenced purely by URL string, so <c>IsOwnUploadUrl</c> could only check the URL's shape
/// (does it start with <c>/uploads/</c>?), not who actually uploaded it. Any authenticated user who
/// had merely *seen* another user's attachment URL (e.g. in a message they could view) could quote
/// that same URL in their own message. This row is what lets <see cref="UploaderUserId"/> actually
/// be checked against the current user before an attachment is accepted.
/// </summary>
public class UploadedFile : BaseEntity
{
    public Guid Id { get; set; }

    public Guid UploaderUserId { get; set; }

    public string Url { get; set; } = null!;

    public UploadPurpose Purpose { get; set; }
}
