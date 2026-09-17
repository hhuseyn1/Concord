using Concord.Application.Enums;

namespace Concord.Domain.Entities;

public class UploadedFile : BaseEntity
{
    public Guid Id { get; set; }

    public Guid UploaderUserId { get; set; }

    public string Url { get; set; } = null!;

    public UploadPurpose Purpose { get; set; }
}
