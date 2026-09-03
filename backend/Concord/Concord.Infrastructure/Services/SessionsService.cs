using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Concord.Infrastructure.Extensions;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

public class SessionsService(ApplicationDbContext context)
{
    private readonly ApplicationDbContext _context = context;

    public async Task<List<Application.Models.SessionResponse>> GetMySessionsAsync(Guid userId, Guid currentSessionId)
    {
        var sessions = await _context.Sessions
            .Where(session => session.UserId == userId)
            .OrderByDescending(session => session.Refreshed ?? session.Created)
            .ToListAsync();

        return sessions.Select(session => session.MapToResponse(currentSessionId)).ToList();
    }

    public async Task RevokeSessionAsync(Guid userId, Guid sessionId)
    {
        var session = await _context.Sessions
            .FirstOrDefaultAsync(session => session.Id == sessionId);

        if (session is null || session.UserId != userId)
            throw new SessionNotFoundException();

        _context.Sessions.Remove(session);

        await _context.SaveChangesAsync();
    }

    public async Task RevokeCurrentSessionAsync(Guid userId, Guid currentSessionId)
    {
        await _context.Sessions
            .Where(session => session.UserId == userId && session.Id == currentSessionId)
            .ExecuteDeleteAsync();
    }

    public async Task RevokeOtherSessionsAsync(Guid userId, Guid currentSessionId)
    {
        await _context.Sessions
            .Where(session => session.UserId == userId && session.Id != currentSessionId)
            .ExecuteDeleteAsync();
    }
}
