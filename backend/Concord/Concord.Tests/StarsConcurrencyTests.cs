using Concord.Application.Models;
using Concord.Domain.Exceptions;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;

namespace Concord.Tests;

public class StarsConcurrencyTests
{
    /// <summary>
    /// Two concurrent transfer requests, each for 80 Stars, against a sender balance of only 100 -
    /// at most one can succeed. Each attempt uses its own <see cref="Concord.Infrastructure.Context.ApplicationDbContext"/>
    /// (mirroring two concurrent ASP.NET Core requests each getting their own scoped context) against
    /// the same underlying database, exercising the same atomic
    /// <c>Users.Where(u => u.Id == id &amp;&amp; u.StarsBalance >= amount).ExecuteUpdateAsync(...)</c>
    /// guard that protects real concurrent Postgres connections from a lost-update race.
    ///
    /// The Sqlite in-memory provider serializes concurrent writers at the connection/database level
    /// rather than exposing Postgres' row-level MVCC locking, so a losing attempt here can surface
    /// as a Sqlite locking exception instead of cleanly reaching the ExecuteUpdateAsync affected-rows
    /// guard and throwing <see cref="InsufficientStarsBalanceException"/>. Either way is treated as
    /// "this attempt did not apply its debit" - what this test actually asserts is the outcome that
    /// matters: exactly one attempt succeeds, and the sender's balance reflects exactly one 80-Star
    /// debit (never negative, never double-debited).
    /// </summary>
    [Fact]
    public async Task Transfer_ConcurrentRequests_OnlyOneSucceeds_BalanceNeverGoesNegative()
    {
        using var db = new TestDatabase();

        Guid senderId;
        Guid recipientId;

        await using (var setupContext = db.CreateContext())
        {
            var sender = StarsServiceTestFactory.CreateUser("concurrentsender");
            var recipient = StarsServiceTestFactory.CreateUser("concurrentrecipient");
            sender.StarsBalance = 100;

            setupContext.Users.AddRange(sender, recipient);
            await setupContext.SaveChangesAsync();
            await StarsServiceTestFactory.MakeFriendsAsync(setupContext, sender.Id, recipient.Id);

            senderId = sender.Id;
            recipientId = recipient.Id;
        }

        async Task<bool> AttemptAsync()
        {
            await using var context = db.CreateContext();
            var service = StarsServiceTestFactory.Create(context);

            try
            {
                await service.TransferAsync(senderId, new TransferStarsRequest
                {
                    RecipientUserId = recipientId,
                    Amount = 80,
                    IdempotencyKey = Guid.NewGuid().ToString()
                });

                return true;
            }
            catch (InsufficientStarsBalanceException)
            {
                return false;
            }
            catch (SqliteException)
            {
                return false;
            }
        }

        var results = await Task.WhenAll(AttemptAsync(), AttemptAsync());

        Assert.Equal(1, results.Count(succeeded => succeeded));

        await using var assertContext = db.CreateContext();
        var senderAfter = await assertContext.Users.FirstAsync(u => u.Id == senderId);

        Assert.True(senderAfter.StarsBalance >= 0, "Sender balance must never go negative.");
        Assert.Equal(20, senderAfter.StarsBalance);
    }
}
