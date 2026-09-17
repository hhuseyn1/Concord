namespace Concord.Application.Models;

public class CreateStarsCheckoutSessionResponse
{
    public string Url { get; set; } = null!;

    /// <summary>
    /// Lets a client poll <c>GET Stars/Purchases/{purchaseId}/Status</c> directly - unlike the web
    /// checkout flow, which gets the id back via the success-redirect query string (see
    /// <see cref="StripeSettings"/>/<c>AppendPurchaseIdQueryParam</c> in <c>StarsService</c>), a
    /// native client never receives that redirect at all, so it has no other way to learn which
    /// purchase row to check.
    /// </summary>
    public Guid PurchaseId { get; set; }
}
