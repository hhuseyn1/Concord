namespace Concord.Application.Models;

public class ActivatePremiumTrialRequest
{
    public string IdempotencyKey { get; set; } = null!;
}
