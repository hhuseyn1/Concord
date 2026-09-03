namespace Concord.Domain.Entities;

public class Server : BaseEntity
{
    public Guid Id { get; set; }

    public string? Name { get; set; }

    public Guid OwnerId { get; set; }

    public string? IconUrl { get; set; }
}
