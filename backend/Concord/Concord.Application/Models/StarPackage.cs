namespace Concord.Application.Models;

/// <summary>One buyable Stars package - see <see cref="StarsConstants.Packages"/>. Stripe Checkout
/// Sessions for these are built with inline price data computed from this record rather than a
/// pre-created Stripe Price object, so the catalog stays fully configurable from code alone.</summary>
public record StarPackage(string Id, int Stars, decimal PriceAmount, string Currency);
