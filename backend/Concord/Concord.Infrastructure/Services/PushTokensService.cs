using Concord.Application.Models;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Concord.Infrastructure.Context;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Services;

public class PushTokensService(ApplicationDbContext context)
{
    private readonly ApplicationDbContext _context = context;

    public async Task RegisterAsync(Guid userId, RegisterPushTokenRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Token))
            throw new ParameterValidationException(nameof(request.Token));

        var existing = await _context.PushTokens.FirstOrDefaultAsync(token => token.Token == request.Token);

        if (existing is not null)
        {
            existing.UserId = userId;
            existing.Platform = request.Platform;
            existing.LastSeenUtc = DateTime.UtcNow;
        }
        else
        {
            _context.PushTokens.Add(new PushToken
            {
                UserId = userId,
                Token = request.Token,
                Platform = request.Platform,
                LastSeenUtc = DateTime.UtcNow
            });
        }

        await _context.SaveChangesAsync();
    }

    public async Task DeregisterAsync(Guid userId, string token)
    {
        await _context.PushTokens
            .Where(pushToken => pushToken.UserId == userId && pushToken.Token == token)
            .ExecuteDeleteAsync();
    }
}
