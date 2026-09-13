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

    public async Task<PagedResult<AdminUserSummary>> GetUsersAsync(int page, int pageSize, string? search)
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

        var users = await query
            .OrderByDescending(user => user.Created)
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
    /// actually needs to narrow the feed: who did it, what kind of action, and when.
    /// </summary>
    public async Task<PagedResult<AuditLogResponse>> GetAuditLogAsync(
        int page, int pageSize, Guid? actorUserId, string? action, DateTime? fromUtc, DateTime? toUtc)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        var query = _context.AuditLogs.AsQueryable();

        if (actorUserId.HasValue)
            query = query.Where(log => log.ActorUserId == actorUserId.Value);

        if (!string.IsNullOrWhiteSpace(action))
            query = query.Where(log => log.Action == action);

        if (fromUtc.HasValue)
            query = query.Where(log => log.Created >= fromUtc.Value);

        if (toUtc.HasValue)
            query = query.Where(log => log.Created <= toUtc.Value);

        var totalCount = await query.CountAsync();

        var logs = await query
            .OrderByDescending(log => log.Created)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Join(_context.Users, log => log.ActorUserId, user => user.Id, (log, user) => new { Log = log, Actor = user })
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
    public async Task<PagedResult<AdminSubscriptionSummary>> GetSubscriptionsAsync(int page, int pageSize, SubscriptionStatus? status)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, GlobalConstants.MaxPageSize);

        var query = _context.Subscriptions.AsQueryable();

        if (status.HasValue)
            query = query.Where(subscription => subscription.Status == status.Value);

        var totalCount = await query.CountAsync();

        var subscriptions = await query
            .OrderByDescending(subscription => subscription.Created)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Join(_context.Users, subscription => subscription.UserId, user => user.Id, (subscription, user) => new { Subscription = subscription, User = user })
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
