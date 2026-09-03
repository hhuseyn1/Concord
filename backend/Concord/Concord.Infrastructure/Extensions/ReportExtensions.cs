using Concord.Application.Models;
using Concord.Domain.Entities;

namespace Concord.Infrastructure.Extensions;

public static class ReportExtensions
{
    public static ReportResponse MapToResponse(this Report report, User reporter, string? targetSnippet) => new()
    {
        Id = report.Id,
        Reporter = reporter.MapToPublicModel(),
        TargetType = report.TargetType,
        TargetId = report.TargetId,
        TargetSnippet = targetSnippet,
        Reason = report.Reason,
        Status = report.Status,
        ResolvedByUserId = report.ResolvedByUserId,
        ResolvedAtUtc = report.ResolvedAtUtc,
        CreatedUtc = report.Created
    };
}
