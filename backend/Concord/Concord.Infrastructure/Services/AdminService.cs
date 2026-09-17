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
            ActiveBans = await _context.ServerBans.CountAsync(ban => ban.ExpiresAtUtc == null || ban.ExpiresAtUtc > now),
            ActiveTimeouts = await _context.ServerMembers.CountAsync(member => member.TimedOutUntil != null && member.TimedOutUntil > now),
            TwoFactorEnabledUsers = await _context.Users.CountAsync(user => user.TwoFactorEnabled),
            ActiveSessions = await _context.Sessions.CountAsync(session => session.Expires > now),
            NewUsersLast7Days = await _context.Users.CountAsync(user => user.Created >= sevenDaysAgo),
            NewServersLast7Days = await _context.Servers.CountAsync(server => server.Created >= sevenDaysAgo)
        };
    }

    private const int MaxChartRangeDays = 366;

    private const int MinUserGrowthYear = 2000;

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

    public async Task<PagedResult<AdminUserSummary>> GetUsersAsync(GetAdminUsersRequest request)
    {
        var page = Math.Max(request.Page, 1);
        var pageSize = Math.Clamp(request.PageSize, 1, GlobalConstants.MaxPageSize);

        var query = _context.Users.AsQueryable();

        if (!string.IsNullOrWhiteSpace(request.Search))
        {
            query = query.Where(user =>
                EF.Functions.ILike(user.Username ?? string.Empty, $"%{request.Search}%") ||
                EF.Functions.ILike(user.Email ?? string.Empty, $"%{request.Search}%") ||
                EF.Functions.ILike(user.Name ?? string.Empty, $"%{request.Search}%") ||
                EF.Functions.ILike(user.Surname ?? string.Empty, $"%{request.Search}%"));
        }

        var totalCount = await query.CountAsync();

        var descending = !string.Equals(request.SortDirection, "Asc", StringComparison.OrdinalIgnoreCase);

        query = (request.SortBy?.ToLowerInvariant()) switch
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
        user.FailedLoginAttempts = 0;
        user.LockoutEnd = null;

        await _context.SaveChangesAsync();

        _logger.LogInformation("User {TargetUserId} re-enabled by admin {AdminUserId}", targetUserId, currentUserId);

        await _auditLogService.LogAsync(currentUserId, "UserEnabled", nameof(Domain.Entities.User), targetUserId);
    }

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

    public async Task<PagedResult<AuditLogResponse>> GetAuditLogAsync(GetAuditLogRequest request)
    {
        var page = Math.Max(request.Page, 1);
        var pageSize = Math.Clamp(request.PageSize, 1, GlobalConstants.MaxPageSize);

        var query = _context.AuditLogs
            .Join(_context.Users, log => log.ActorUserId, user => user.Id, (log, user) => new { Log = log, Actor = user });

        if (!string.IsNullOrWhiteSpace(request.ActorEmail))
            query = query.Where(entry => EF.Functions.ILike(entry.Actor.Email ?? string.Empty, $"%{request.ActorEmail}%"));

        if (!string.IsNullOrWhiteSpace(request.Action))
            query = query.Where(entry => entry.Log.Action == request.Action);

        if (request.FromUtc.HasValue)
            query = query.Where(entry => entry.Log.Created >= request.FromUtc.Value);

        if (request.ToUtc.HasValue)
            query = query.Where(entry => entry.Log.Created <= request.ToUtc.Value);

        var totalCount = await query.CountAsync();

        var descending = !string.Equals(request.SortDirection, "Asc", StringComparison.OrdinalIgnoreCase);

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

    public async Task<PagedResult<AdminSubscriptionSummary>> GetSubscriptionsAsync(GetAdminSubscriptionsRequest request)
    {
        var page = Math.Max(request.Page, 1);
        var pageSize = Math.Clamp(request.PageSize, 1, GlobalConstants.MaxPageSize);

        var query = _context.Subscriptions
            .Join(_context.Users, subscription => subscription.UserId, user => user.Id, (subscription, user) => new { Subscription = subscription, User = user });

        if (request.Status.HasValue)
            query = query.Where(entry => entry.Subscription.Status == request.Status.Value);

        if (request.FromUtc.HasValue)
            query = query.Where(entry => entry.Subscription.Created >= request.FromUtc.Value);

        if (request.ToUtc.HasValue)
            query = query.Where(entry => entry.Subscription.Created <= request.ToUtc.Value);

        if (!string.IsNullOrWhiteSpace(request.Search))
        {
            query = query.Where(entry =>
                EF.Functions.ILike(entry.User.Username ?? string.Empty, $"%{request.Search}%") ||
                EF.Functions.ILike(entry.User.Email ?? string.Empty, $"%{request.Search}%"));
        }

        var totalCount = await query.CountAsync();

        var descending = !string.Equals(request.SortDirection, "Asc", StringComparison.OrdinalIgnoreCase);

        query = (request.SortBy?.ToLowerInvariant()) switch
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
