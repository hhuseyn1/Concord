using Concord.Infrastructure.Context;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace Concord.API.HealthChecks;

/// <summary>Readiness check (P2.14) - confirms the database is actually reachable, not just that
/// the process is up (that's /health/live's job).</summary>
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
