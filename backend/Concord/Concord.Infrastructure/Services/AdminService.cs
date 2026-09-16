using Concord.Application.Auditing;
using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Domain.Enums;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Extensions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Concord.Infrastructure.Services;

/// <summary>
/// Site-wide admin surface (P4): the overview stats and user-management actions
/// <see cref="AdminController"/> exposes to accounts with <see cref="Roles.Admin"/>.
///
/// This is deliberately global, not per-server - it is scoped by <c>[Authorize(Roles = "Admin")]</c>
/// against the <see cref="Domain.Entities.User.Role"/> claim, unrelated to the server-scoped RBAC
/// from P0 (<c>PermissionService</c>/<c>ServerPermission</c>). A server owner with every permission
/// on their own server has none of these capabilities; only the seeded site admin (and anyone
/// promoted here) does.
/// </summary>
public class AdminService(ApplicationDbContext context, IAuditLogService auditLogService, ILogger<AdminService> logger)
{
    private readonly ApplicationDbContext _context = context;
    private readonly IAuditLogService _auditLogService = auditLogService;
    private readonly ILogger<AdminService> _logger = logger;

    public async Task<AdminOverviewResponse> GetOverviewAsync()
    {
        var now = DateTime.UtcNow;
        var sevenDaysAgo = now.AddDays(-7);

        return new AdminOverviewResponse
        {
            TotalUsers = await _context.Users.CountAsync(),
            DisabledUsers = await _context.Users.CountAsync(user => user.Disabled != null),
            TotalServers = await _context.Servers.CountAsync(),
            TotalMessages = await _context.Messages.CountAsync(),
            TotalDirectMessages = await _context.DirectMessages.CountAsync(),
            // Mirrors ModerationService.GetBansAsync's definition of "active": no expiry, or an
            // expiry that hasn't passed yet.
            ActiveBans = await _context.ServerBans.CountAsync(ban => ban.ExpiresAtUtc == null || ban.ExpiresAtUtc > now),
            ActiveTimeouts = await _context.ServerMembers.CountAsync(member => member.TimedOutUntil != null && member.TimedOutUntil > now),
            TwoFactorEnabledUsers = await _context.Users.CountAsync(user => user.TwoFactorEnabled),
            // Sessions have no "last active" column, only an expiry, so an unexpired session is the
            // closest available proxy for "currently signed in" - it over-counts idle-but-valid
            // sessions rather than under-counting, which is the safer direction for an admin metric.
            ActiveSessions = await _context.Sessions.CountAsync(session => session.Expires > now),
            NewUsersLast7Days = await _context.Users.CountAsync(user => user.Created >= sevenDaysAgo),
            NewServersLast7Days = await _context.Servers.CountAsync(server => server.Created >= sevenDaysAgo)
        };
    }

    /// <summary>
    /// Maximum span (in days) allowed between <c>fromUtc</c>/<c>toUtc</c> in <see cref="GetOverviewChartsAsync"/> -
    /// this is an admin-only, low-traffic endpoint, but an unbounded day-bucketed query isn't worth allowing.
    /// </summary>
    private const int MaxChartRangeDays = 366;

    /// <summary>
    /// Earliest year <see cref="GetUserGrowthAsync"/> accepts - well before the product existed, just
    /// enough to reject obviously-wrong input without hardcoding a launch date that could change.
    /// </summary>
    private const int MinUserGrowthYear = 2000;

    /// <summary>
    /// Date-filterable chart data for the overview page (P4): a subscriptions-by-status breakdown
    /// scoped to <c>[fromUtc, toUtc]</c>. If either bound is omitted, the range defaults to the last 14
    /// days ending now, matching the fixed window this data used to be hardcoded to before it moved to
    /// its own endpoint.
    /// </summary>
    public async Task<AdminOverviewChartsResponse> GetOverviewChartsAsync(DateTime? fromUtc, DateTime? toUtc)
    {
        var now = DateTime.UtcNow;

        DateTime rangeStart;
        DateTime rangeEnd;

        if (fromUtc is null || toUtc is null)
        {
            rangeEnd = now;
            rangeStart = now.AddDays(-13);
        }
        else
        {
            rangeStart = fromUtc.Value;
            rangeEnd = toUtc.Value;
        }

        // Query-string-bound DateTime values from ASP.NET Core's model binding may or may not already
        // have Kind = Utc depending on the format the caller sent - Npgsql refuses to compare a
        // DateTimeKind.Unspecified value against a "timestamp with time zone" column, so normalize
        // defensively the same way GetUserGrowthAsync already has to.
        rangeStart = DateTime.SpecifyKind(rangeStart, DateTimeKind.Utc);
        rangeEnd = DateTime.SpecifyKind(rangeEnd, DateTimeKind.Utc);

        if (rangeStart > rangeEnd)
            throw new ParameterValidationException(nameof(fromUtc));

        if ((rangeEnd - rangeStart).TotalDays > MaxChartRangeDays)
            throw new ParameterValidationException(nameof(fromUtc));

        return new AdminOverviewChartsResponse
        {
            SubscriptionsByStatus = await GetSubscriptionsByStatusAsync(rangeStart, rangeEnd)
        };
    }

    /// <summary>
    /// Monthly new-user counts across the given calendar year (UTC), one entry per month
    /// (Jan-Dec, oldest first), including months with zero signups. Defaults to the current year when
    /// <paramref name="year"/> is omitted. This is an admin-only, infrequently-hit query over a single
    /// year, so it pulls the raw <c>Created</c> timestamps and buckets them into months in memory
    /// rather than pushing a date-truncating GroupBy down to SQL.
    /// </summary>
    public async Task<List<AdminUserGrowthPoint>> GetUserGrowthAsync(int? year)
    {
        var now = DateTime.UtcNow;
        var targetYear = year ?? now.Year;

        if (targetYear < MinUserGrowthYear || targetYear > now.Year)
            throw new ParameterValidationException(nameof(year));

        var rangeStart = new DateTime(targetYear, 1, 1, 0, 0, 0, DateTimeKind.Utc);
        var rangeEndExclusive = rangeStart.AddYears(1);

        var createdDates = await _context.Users
            .Where(user => user.Created >= rangeStart && user.Created < rangeEndExclusive)
            .Select(user => user.Created)
            .ToListAsync();

        var countsByMonth = createdDates
            .GroupBy(created => created.Month)
            .ToDictionary(group => group.Key, group => group.Count());

        var points = new List<AdminUserGrowthPoint>();

        for (var month = 1; month <= 12; month++)
        {
            points.Add(new AdminUserGrowthPoint
            {
                Date = new DateOnly(targetYear, month, 1),
                Count = countsByMonth.GetValueOrDefault(month)
            });
        }

        return points;
    }

    /// <summary>
    /// Counts of Subscription rows created within <c>[fromUtc, toUtc]</c>, by status. Like
    /// <see cref="GetSubscriptionsAsync"/>, this is a count of historical rows, not deduplicated
    /// users - a resubscribed user contributes multiple rows, which is intentional here too.
    /// </summary>
    private async Task<AdminSubscriptionStatusBreakdown> GetSubscriptionsByStatusAsync(DateTime fromUtc, DateTime toUtc)
    {
        var counts = await _context.Subscriptions
            .Where(subscription => subscription.Created >= fromUtc && subscription.Created <= toUtc)
            .GroupBy(subscription => subscription.Status)
            .Select(group => new { Status = group.Key, Count = group.Count() })
            .ToListAsync();

        var breakdown = new AdminSubscriptionStatusBreakdown();

        foreach (var entry in counts)
        {
            switch (entry.Status)
            {
                case SubscriptionStatus.Active:
                    breakdown.Active = entry.Count;
                    break;
                case SubscriptionStatus.PastDue:
                    breakdown.PastDue = entry.Count;
                    break;
                case SubscriptionStatus.Canceled:
                    breakdown.Canceled = entry.Count;
                    break;
            }
        }

        return breakdown;
    }

    public async Task<PagedResult<AdminUserSummary>> GetUsersAsync(int page, int pageSize, string? search, string? sortBy, string? sortDirection)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        var query = _context.Users.AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            // ILike over the same three fields UsersService.SearchByUsernameAsync already searches,
            // plus Email - the one field an admin needs that a public search deliberately excludes.
            query = query.Where(user =>
                EF.Functions.ILike(user.Username ?? string.Empty, $"%{search}%") ||
                EF.Functions.ILike(user.Email ?? string.Empty, $"%{search}%") ||
                EF.Functions.ILike(user.Name ?? string.Empty, $"%{search}%") ||
                EF.Functions.ILike(user.Surname ?? string.Empty, $"%{search}%"));
        }

        var totalCount = await query.CountAsync();

        var descending = !string.Equals(sortDirection, "Asc", StringComparison.OrdinalIgnoreCase);

        // Every branch ends with ThenBy(user => user.Id) - a deterministic tiebreaker for rows tied
        // on the primary sort key (e.g. identical Created timestamps, or many null PhoneNumbers).
        // Without it, Postgres can return tied rows in a different order across separate query
        // executions with no data change at all, which visually reorders the list on every refetch.
        query = (sortBy?.ToLowerInvariant()) switch
        {
            "name" => descending
                ? query.OrderByDescending(user => user.Name).ThenBy(user => user.Id)
                : query.OrderBy(user => user.Name).ThenBy(user => user.Id),
            "surname" => descending
                ? query.OrderByDescending(user => user.Surname).ThenBy(user => user.Id)
                : query.OrderBy(user => user.Surname).ThenBy(user => user.Id),
            "email" => descending
                ? query.OrderByDescending(user => user.Email).ThenBy(user => user.Id)
                : query.OrderBy(user => user.Email).ThenBy(user => user.Id),
            "phonenumber" => descending
                ? query.OrderByDescending(user => user.PhoneNumber).ThenBy(user => user.Id)
                : query.OrderBy(user => user.PhoneNumber).ThenBy(user => user.Id),
            _ => descending
                ? query.OrderByDescending(user => user.Created).ThenBy(user => user.Id)
                : query.OrderBy(user => user.Created).ThenBy(user => user.Id)
        };

        var users = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<AdminUserSummary>
        {
            Items = users.Select(user => user.MapToAdminSummary()).ToList(),
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    /// <summary>
    /// Disables an account: blocks future logins (checked in <c>AuthenticationService.LoginAsync</c>
    /// and every path that loads a user for an authenticated action) and revokes every existing
    /// session immediately, the same way <c>LogoutAllAsync</c> does - otherwise a disabled account
    /// would stay usable until its access token happened to expire.
    /// </summary>
    public async Task DisableUserAsync(Guid currentUserId, Guid targetUserId)
    {
        if (targetUserId == currentUserId)
            throw new CannotDisableSelfException();

        var user = await GetUserAsync(targetUserId);

        user.Disabled = DateTime.UtcNow;

        await _context.Sessions.Where(session => session.UserId == targetUserId).ExecuteDeleteAsync();

        await _context.SaveChangesAsync();

        _logger.LogWarning("User {TargetUserId} disabled by admin {AdminUserId}", targetUserId, currentUserId);

        await _auditLogService.LogAsync(currentUserId, "UserDisabled", nameof(Domain.Entities.User), targetUserId);
    }

    public async Task EnableUserAsync(Guid currentUserId, Guid targetUserId)
    {
        var user = await GetUserAsync(targetUserId);

        user.Disabled = null;
        // A fresh start rather than a partially-spent one: whatever locked them out before being
        // disabled should not immediately re-trigger.
        user.FailedLoginAttempts = 0;
        user.LockoutEnd = null;

        await _context.SaveChangesAsync();

        _logger.LogInformation("User {TargetUserId} re-enabled by admin {AdminUserId}", targetUserId, currentUserId);

        await _auditLogService.LogAsync(currentUserId, "UserEnabled", nameof(Domain.Entities.User), targetUserId);
    }

    /// <summary>
    /// Promotes or demotes site-admin status. Distinct from every P0 role concept - this is the
    /// single global <see cref="Roles"/> flag, not a server's <c>Role</c> row.
    /// </summary>
    public async Task SetUserRoleAsync(Guid currentUserId, Guid targetUserId, string? role)
    {
        if (!Enum.TryParse<Roles>(role, ignoreCase: true, out var parsedRole))
            throw new InvalidRoleException();

        if (targetUserId == currentUserId)
            throw new CannotTargetSelfException();

        var user = await GetUserAsync(targetUserId);

        var oldRole = user.Role;

        user.Role = parsedRole;

        await _context.SaveChangesAsync();

        _logger.LogWarning("User {TargetUserId} role set to {Role} by admin {AdminUserId}", targetUserId, parsedRole, currentUserId);

        await _auditLogService.LogAsync(
            currentUserId,
            "RoleChanged",
            nameof(Domain.Entities.User),
            targetUserId,
            System.Text.Json.JsonSerializer.Serialize(new { OldRole = oldRole.ToString(), NewRole = parsedRole.ToString() }));
    }

    /// <summary>
    /// Read side of the audit trail (Item 2) - filters are deliberately limited to what an admin
    /// actually needs to narrow the feed: who did it, what kind of action, and when. The actor is
    /// filtered by email (an admin recognizes a person by email, not by an opaque Guid), so the join
    /// against Users has to happen before filtering/sorting/paging rather than after, unlike the
    /// original Guid-based lookup.
    /// </summary>
    public async Task<PagedResult<AuditLogResponse>> GetAuditLogAsync(
        int page, int pageSize, string? actorEmail, string? action, DateTime? fromUtc, DateTime? toUtc, string? sortDirection)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        var query = _context.AuditLogs
            .Join(_context.Users, log => log.ActorUserId, user => user.Id, (log, user) => new { Log = log, Actor = user });

        if (!string.IsNullOrWhiteSpace(actorEmail))
            query = query.Where(entry => EF.Functions.ILike(entry.Actor.Email ?? string.Empty, $"%{actorEmail}%"));

        if (!string.IsNullOrWhiteSpace(action))
            query = query.Where(entry => entry.Log.Action == action);

        if (fromUtc.HasValue)
            query = query.Where(entry => entry.Log.Created >= fromUtc.Value);

        if (toUtc.HasValue)
            query = query.Where(entry => entry.Log.Created <= toUtc.Value);

        var totalCount = await query.CountAsync();

        var descending = !string.Equals(sortDirection, "Asc", StringComparison.OrdinalIgnoreCase);

        // A deterministic tiebreaker for rows with identical Created timestamps - see GetUsersAsync
        // for why this matters (Postgres has no stable order among ties otherwise).
        query = descending
            ? query.OrderByDescending(entry => entry.Log.Created).ThenBy(entry => entry.Log.Id)
            : query.OrderBy(entry => entry.Log.Created).ThenBy(entry => entry.Log.Id);

        var logs = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<AuditLogResponse>
        {
            Items = logs.Select(entry => entry.Log.MapToResponse(entry.Actor)).ToList(),
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    /// <summary>
    /// Read side of billing (P4) - an audit view of subscription history, not a deduplicated "who is
    /// currently subscribed" list, so every <see cref="Domain.Entities.Subscription"/> row is returned
    /// (past/canceled included). See <see cref="GetUsersAsync"/> for the per-user view instead.
    /// </summary>
    public async Task<PagedResult<AdminSubscriptionSummary>> GetSubscriptionsAsync(
        int page, int pageSize, SubscriptionStatus? status, string? search, string? sortBy, string? sortDirection,
        DateTime? fromUtc, DateTime? toUtc)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        // The join is moved ahead of Where/OrderBy/Skip/Take (unlike the old Subscription-only
        // query) because search and the Username/Email sort options need User columns before
        // filtering, sorting, and paging are applied - the count and page must both reflect the
        // fully filtered set, not just the current page's rows.
        var query = _context.Subscriptions
            .Join(_context.Users, subscription => subscription.UserId, user => user.Id, (subscription, user) => new { Subscription = subscription, User = user });

        if (status.HasValue)
            query = query.Where(entry => entry.Subscription.Status == status.Value);

        if (fromUtc.HasValue)
            query = query.Where(entry => entry.Subscription.Created >= fromUtc.Value);

        if (toUtc.HasValue)
            query = query.Where(entry => entry.Subscription.Created <= toUtc.Value);

        if (!string.IsNullOrWhiteSpace(search))
        {
            // ILike over the same two fields this view displays for a subscription row.
            query = query.Where(entry =>
                EF.Functions.ILike(entry.User.Username ?? string.Empty, $"%{search}%") ||
                EF.Functions.ILike(entry.User.Email ?? string.Empty, $"%{search}%"));
        }

        var totalCount = await query.CountAsync();

        var descending = !string.Equals(sortDirection, "Asc", StringComparison.OrdinalIgnoreCase);

        // Every branch ends with ThenBy(entry => entry.Subscription.Id) - see GetUsersAsync for why
        // a deterministic tiebreaker matters (Postgres has no stable order among ties otherwise).
        query = (sortBy?.ToLowerInvariant()) switch
        {
            "username" => descending
                ? query.OrderByDescending(entry => entry.User.Username).ThenBy(entry => entry.Subscription.Id)
                : query.OrderBy(entry => entry.User.Username).ThenBy(entry => entry.Subscription.Id),
            "email" => descending
                ? query.OrderByDescending(entry => entry.User.Email).ThenBy(entry => entry.Subscription.Id)
                : query.OrderBy(entry => entry.User.Email).ThenBy(entry => entry.Subscription.Id),
            "status" => descending
                ? query.OrderByDescending(entry => entry.Subscription.Status).ThenBy(entry => entry.Subscription.Id)
                : query.OrderBy(entry => entry.Subscription.Status).ThenBy(entry => entry.Subscription.Id),
            "currentperiodend" => descending
                ? query.OrderByDescending(entry => entry.Subscription.CurrentPeriodEnd).ThenBy(entry => entry.Subscription.Id)
                : query.OrderBy(entry => entry.Subscription.CurrentPeriodEnd).ThenBy(entry => entry.Subscription.Id),
            _ => descending
                ? query.OrderByDescending(entry => entry.Subscription.Created).ThenBy(entry => entry.Subscription.Id)
                : query.OrderBy(entry => entry.Subscription.Created).ThenBy(entry => entry.Subscription.Id)
        };

        var subscriptions = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<AdminSubscriptionSummary>
        {
            Items = subscriptions.Select(entry => entry.Subscription.MapToAdminSummary(entry.User)).ToList(),
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    private async Task<Domain.Entities.User> GetUserAsync(Guid userId)
    {
        return await _context.Users.FirstOrDefaultAsync(user => user.Id == userId)
            ?? throw new UserNotFoundException(userId);
    }
}
