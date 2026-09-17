using Concord.Infrastructure.Context;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace Concord.API.HealthChecks;

public class DatabaseHealthCheck(ApplicationDbContext context) : IHealthCheck
{
    private readonly ApplicationDbContext _context = context;

    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        return await _context.Database.CanConnectAsync(cancellationToken)
            ? HealthCheckResult.Healthy()
            : HealthCheckResult.Unhealthy("Database unreachable.");
    }
}
