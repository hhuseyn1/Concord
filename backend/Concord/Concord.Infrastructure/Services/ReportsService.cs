using Concord.Application.Auditing;
using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Application.Realtime;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Extensions;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

/// <summary>
/// The report/flag system and moderator queue. Unlike <see cref="ModerationService"/>/<see cref="AdminService"/>,
/// a report's target is polymorphic (a channel message, a DM, or a user) and carries no FK -
/// <see cref="Report.TargetId"/> is validated for existence and reporter access here, at write time,
/// rather than by the database.
/// </summary>
public class ReportsService(
    ApplicationDbContext context,
    ChannelsService channelsService,
    DirectMessagesService directMessagesService,
    IAuditLogService auditLogService,
    NotificationsService notificationsService,
    INotificationsRealtimeNotifier notificationsRealtimeNotifier)
{
    /// <summary>Matches ModerationService's ban/timeout reason ceiling.</summary>
    private const int MaxReasonLength = 500;

    private const int MaxSnippetLength = 200;

    private readonly ApplicationDbContext _context = context;
    private readonly ChannelsService _channelsService = channelsService;
    private readonly DirectMessagesService _directMessagesService = directMessagesService;
    private readonly IAuditLogService _auditLogService = auditLogService;
    private readonly NotificationsService _notificationsService = notificationsService;
    private readonly INotificationsRealtimeNotifier _notificationsRealtimeNotifier = notificationsRealtimeNotifier;

    public async Task<ReportResponse> CreateReportAsync(Guid currentUserId, CreateReportRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Reason) || request.Reason.Length > MaxReasonLength)
            throw new ParameterValidationException(nameof(request.Reason));

        if (request.TargetType == ReportTargetType.Message)
            await AssertMessageTargetAsync(currentUserId, request.TargetId);
        else
            await AssertUserTargetAsync(currentUserId, request.TargetId);

        var report = new Report
        {
            ReporterUserId = currentUserId,
            TargetType = request.TargetType,
            TargetId = request.TargetId,
            Reason = request.Reason,
            Status = ReportStatus.Pending
        };

        _context.Reports.Add(report);

        await _context.SaveChangesAsync();

        var reporter = await _context.Users.FirstAsync(user => user.Id == currentUserId);
        var snippet = await BuildTargetSnippetAsync(report.TargetType, report.TargetId);

        return report.MapToResponse(reporter, snippet);
    }

    public async Task<PagedResult<ReportResponse>> GetReportsAsync(
        int page, int pageSize, ReportStatus? status, string? search, string? sortBy, string? sortDirection)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        // Joined against Users up front (like AdminService's Subscriptions/AuditLog queries) so
        // search and the reporter-name sort option can see User columns before filtering, sorting,
        // and paging happen - and so a report from a since-deleted reporter (no profile to show,
        // same case the old in-memory skip handled) is naturally excluded by the inner join instead
        // of being counted in TotalCount and then silently dropped from Items.
        var query = _context.Reports
            .Join(_context.Users, report => report.ReporterUserId, user => user.Id, (report, user) => new { Report = report, Reporter = user });

        if (status.HasValue)
            query = query.Where(entry => entry.Report.Status == status.Value);

        if (!string.IsNullOrWhiteSpace(search))
        {
            query = query.Where(entry =>
                EF.Functions.ILike(entry.Report.Reason, $"%{search}%") ||
                EF.Functions.ILike(entry.Reporter.Username ?? string.Empty, $"%{search}%") ||
                EF.Functions.ILike(entry.Reporter.Email ?? string.Empty, $"%{search}%"));
        }

        var totalCount = await query.CountAsync();

        var descending = !string.Equals(sortDirection, "Asc", StringComparison.OrdinalIgnoreCase);

        // Every branch ends with ThenBy(entry => entry.Report.Id) - see AdminService.GetUsersAsync
        // for why a deterministic tiebreaker matters (Postgres has no stable order among ties otherwise).
        query = (sortBy?.ToLowerInvariant()) switch
        {
            "reporter" => descending
                ? query.OrderByDescending(entry => entry.Reporter.Username).ThenBy(entry => entry.Report.Id)
                : query.OrderBy(entry => entry.Reporter.Username).ThenBy(entry => entry.Report.Id),
            "status" => descending
                ? query.OrderByDescending(entry => entry.Report.Status).ThenBy(entry => entry.Report.Id)
                : query.OrderBy(entry => entry.Report.Status).ThenBy(entry => entry.Report.Id),
            _ => descending
                ? query.OrderByDescending(entry => entry.Report.Created).ThenBy(entry => entry.Report.Id)
                : query.OrderBy(entry => entry.Report.Created).ThenBy(entry => entry.Report.Id)
        };

        var pageEntries = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var items = new List<ReportResponse>(pageEntries.Count);

        foreach (var entry in pageEntries)
        {
            var snippet = await BuildTargetSnippetAsync(entry.Report.TargetType, entry.Report.TargetId);
            items.Add(entry.Report.MapToResponse(entry.Reporter, snippet));
        }

        return new PagedResult<ReportResponse>
        {
            Items = items,
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    public async Task ResolveReportAsync(Guid adminUserId, Guid reportId)
    {
        await ReviewReportAsync(adminUserId, reportId, ReportStatus.Resolved, "ReportResolved", reason: null);
    }

    public async Task DismissReportAsync(Guid adminUserId, Guid reportId, string? reason)
    {
        if (!string.IsNullOrEmpty(reason) && reason.Length > MaxReasonLength)
            throw new ParameterValidationException(nameof(reason));

        await ReviewReportAsync(adminUserId, reportId, ReportStatus.Dismissed, "ReportDismissed", reason);
    }

    private async Task ReviewReportAsync(Guid adminUserId, Guid reportId, ReportStatus newStatus, string auditAction, string? reason)
    {
        var report = await _context.Reports.FirstOrDefaultAsync(report => report.Id == reportId)
            ?? throw new ReportNotFoundException();

        if (report.Status != ReportStatus.Pending)
            throw new ReportAlreadyReviewedException();

        report.Status = newStatus;
        report.ResolvedByUserId = adminUserId;
        report.ResolvedAtUtc = DateTime.UtcNow;

        if (newStatus == ReportStatus.Dismissed)
            _notificationsService.NotifyReportDismissed(report.ReporterUserId, reason);

        await _context.SaveChangesAsync();

        if (newStatus == ReportStatus.Dismissed)
        {
            await _notificationsRealtimeNotifier.NotifyAsync(
                report.ReporterUserId, NotificationType.ReportDismissed, relatedUserId: null, reason: reason);
        }

        await _auditLogService.LogAsync(
            adminUserId,
            auditAction,
            nameof(Report),
            report.Id,
            newStatus == ReportStatus.Dismissed
                ? System.Text.Json.JsonSerializer.Serialize(new { Reason = reason })
                : null);
    }

    /// <summary>Verifies the message exists (checking both the channel-message and direct-message
    /// tables, since a bare Guid cannot tell which one it is) and that the reporter can currently view
    /// it - the same access gate <see cref="ForwardingService"/> relies on for each table.</summary>
    private async Task AssertMessageTargetAsync(Guid currentUserId, Guid messageId)
    {
        var channelMessage = await _context.Messages.FirstOrDefaultAsync(message => message.Id == messageId);

        if (channelMessage is not null)
        {
            await _channelsService.AssertChannelMemberAsync(currentUserId, channelMessage.ChannelId);
            return;
        }

        var directMessage = await _context.DirectMessages.FirstOrDefaultAsync(message => message.Id == messageId);

        if (directMessage is not null)
        {
            await _directMessagesService.AssertConversationAccessAsync(currentUserId, directMessage.ConversationId);
            return;
        }

        throw new MessageNotFoundException();
    }

    private async Task AssertUserTargetAsync(Guid currentUserId, Guid targetUserId)
    {
        if (targetUserId == currentUserId)
            throw new CannotTargetSelfException();

        if (!await _context.Users.AnyAsync(user => user.Id == targetUserId))
            throw new UserNotFoundException(targetUserId);
    }

    /// <summary>Best-effort preview for the admin queue - returns null rather than throwing when the
    /// target has since been hard-deleted, so a stale report still renders instead of failing the
    /// whole list.</summary>
    private async Task<string?> BuildTargetSnippetAsync(ReportTargetType targetType, Guid targetId)
    {
        if (targetType == ReportTargetType.User)
        {
            var user = await _context.Users.FirstOrDefaultAsync(user => user.Id == targetId);
            return user is null ? null : (user.Username ?? $"{user.Name} {user.Surname}".Trim());
        }

        var channelMessage = await _context.Messages.FirstOrDefaultAsync(message => message.Id == targetId);

        if (channelMessage is not null)
            return Truncate(channelMessage.Content);

        var directMessage = await _context.DirectMessages.FirstOrDefaultAsync(message => message.Id == targetId);

        return directMessage is null ? null : Truncate(directMessage.Content);
    }

    private static string? Truncate(string? content)
    {
        if (string.IsNullOrEmpty(content))
            return content;

        return content.Length <= MaxSnippetLength ? content : content[..MaxSnippetLength];
    }
}
