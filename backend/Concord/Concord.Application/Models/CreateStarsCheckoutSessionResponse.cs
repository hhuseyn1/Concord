namespace Concord.Application.Models;

public class CreateStarsCheckoutSessionResponse
{
    public string Url { get; set; } = null!;

    public Guid PurchaseId { get; set; }
}
