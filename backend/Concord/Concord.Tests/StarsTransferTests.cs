using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Domain.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace Concord.Tests;

/// <summary>
/// Every test uses a separate <see cref="Concord.Infrastructure.Context.ApplicationDbContext"/> per
/// phase (seed / act / assert) - mirroring how each ASP.NET Core request gets its own scoped
/// DbContext in production - rather than reusing one context throughout. Reusing a single context
/// across seeding and the service call left stale tracked entities behind that could shadow the
/// fresh values <c>ExecuteUpdateAsync</c> had just written, which is a test-only artifact, not a
/// StarsService bug.
/// </summary>
public class StarsTransferTests
{
    [Fact]
    public async Task Transfer_InsufficientBalance_Throws()
    {
        using var db = new TestDatabase();

        Guid senderId, recipientId;
        await using (var seed = db.CreateContext())
        {
            var sender = StarsServiceTestFactory.CreateUser("sender");
            var recipient = StarsServiceTestFactory.CreateUser("recipient");
            sender.StarsBalance = 10;

            seed.Users.AddRange(sender, recipient);
            await seed.SaveChangesAsync();
            await StarsServiceTestFactory.MakeFriendsAsync(seed, sender.Id, recipient.Id);

            senderId = sender.Id;
            recipientId = recipient.Id;
        }

        await using (var actContext = db.CreateContext())
        {
            var service = StarsServiceTestFactory.Create(actContext);

            await Assert.ThrowsAsync<InsufficientStarsBalanceException>(() => service.TransferAsync(senderId, new TransferStarsRequest
            {
                RecipientUserId = recipientId,
                Amount = 50,
                IdempotencyKey = Guid.NewGuid().ToString()
            }));
        }

        await using (var assertContext = db.CreateContext())
        {
            var senderAfter = await assertContext.Users.FirstAsync(u => u.Id == senderId);
            Assert.Equal(10, senderAfter.StarsBalance);
        }
    }

    [Fact]
    public async Task Transfer_ToSelf_Throws()
    {
        using var db = new TestDatabase();

        Guid userId;
        await using (var seed = db.CreateContext())
        {
            var user = StarsServiceTestFactory.CreateUser("solo");
            user.StarsBalance = 100;

            seed.Users.Add(user);
            await seed.SaveChangesAsync();

            userId = user.Id;
        }

        await using var actContext = db.CreateContext();
        var service = StarsServiceTestFactory.Create(actContext);

        await Assert.ThrowsAsync<CannotTargetSelfException>(() => service.TransferAsync(userId, new TransferStarsRequest
        {
            RecipientUserId = userId,
            Amount = 10,
            IdempotencyKey = Guid.NewGuid().ToString()
        }));
    }

    [Fact]
    public async Task Transfer_ToNonFriend_Throws()
    {
        using var db = new TestDatabase();

        Guid senderId, strangerId;
        await using (var seed = db.CreateContext())
        {
            var sender = StarsServiceTestFactory.CreateUser("sender2");
            var stranger = StarsServiceTestFactory.CreateUser("stranger");
            sender.StarsBalance = 100;

            seed.Users.AddRange(sender, stranger);
            await seed.SaveChangesAsync();
            // Deliberately not calling MakeFriendsAsync - sender and stranger are not friends.

            senderId = sender.Id;
            strangerId = stranger.Id;
        }

        await using (var actContext = db.CreateContext())
        {
            var service = StarsServiceTestFactory.Create(actContext);

            await Assert.ThrowsAsync<NotFriendsException>(() => service.TransferAsync(senderId, new TransferStarsRequest
            {
                RecipientUserId = strangerId,
                Amount = 10,
                IdempotencyKey = Guid.NewGuid().ToString()
            }));
        }

        await using (var assertContext = db.CreateContext())
        {
            var senderAfter = await assertContext.Users.FirstAsync(u => u.Id == senderId);
            Assert.Equal(100, senderAfter.StarsBalance);
        }
    }

    [Fact]
    public async Task Transfer_Success_MovesBothBalancesAndWritesBothLedgerRowsAtomically()
    {
        using var db = new TestDatabase();

        Guid senderId, recipientId;
        await using (var seed = db.CreateContext())
        {
            var sender = StarsServiceTestFactory.CreateUser("richguy");
            var recipient = StarsServiceTestFactory.CreateUser("poorguy");
            sender.StarsBalance = 100;
            recipient.StarsBalance = 5;

            seed.Users.AddRange(sender, recipient);
            await seed.SaveChangesAsync();
            await StarsServiceTestFactory.MakeFriendsAsync(seed, sender.Id, recipient.Id);

            senderId = sender.Id;
            recipientId = recipient.Id;
        }

        await using (var actContext = db.CreateContext())
        {
            var service = StarsServiceTestFactory.Create(actContext);

            var response = await service.TransferAsync(senderId, new TransferStarsRequest
            {
                RecipientUserId = recipientId,
                Amount = 30,
                IdempotencyKey = Guid.NewGuid().ToString()
            });

            Assert.Equal(70, response.Balance);
        }

        await using (var assertContext = db.CreateContext())
        {
            var senderAfter = await assertContext.Users.FirstAsync(u => u.Id == senderId);
            var recipientAfter = await assertContext.Users.FirstAsync(u => u.Id == recipientId);

            Assert.Equal(70, senderAfter.StarsBalance);
            Assert.Equal(35, recipientAfter.StarsBalance);

            var senderLedger = await assertContext.StarTransactions.SingleAsync(t => t.UserId == senderId);
            var recipientLedger = await assertContext.StarTransactions.SingleAsync(t => t.UserId == recipientId);

            Assert.Equal(StarTransactionType.TransferSent, senderLedger.Type);
            Assert.Equal(-30, senderLedger.Amount);
            Assert.Equal(70, senderLedger.BalanceAfter);
            Assert.Equal(recipientId, senderLedger.CounterpartyUserId);

            Assert.Equal(StarTransactionType.TransferReceived, recipientLedger.Type);
            Assert.Equal(30, recipientLedger.Amount);
            Assert.Equal(35, recipientLedger.BalanceAfter);
            Assert.Equal(senderId, recipientLedger.CounterpartyUserId);
        }
    }

    [Fact]
    public async Task Transfer_DuplicateIdempotencyKey_DoesNotDoubleSpend()
    {
        using var db = new TestDatabase();

        Guid senderId, recipientId;
        await using (var seed = db.CreateContext())
        {
            var sender = StarsServiceTestFactory.CreateUser("retryguy");
            var recipient = StarsServiceTestFactory.CreateUser("receiverguy");
            sender.StarsBalance = 100;

            seed.Users.AddRange(sender, recipient);
            await seed.SaveChangesAsync();
            await StarsServiceTestFactory.MakeFriendsAsync(seed, sender.Id, recipient.Id);

            senderId = sender.Id;
            recipientId = recipient.Id;
        }

        var idempotencyKey = Guid.NewGuid().ToString();

        TransferStarsResponse first, second;

        await using (var firstContext = db.CreateContext())
        {
            var service = StarsServiceTestFactory.Create(firstContext);

            first = await service.TransferAsync(senderId, new TransferStarsRequest
            {
                RecipientUserId = recipientId,
                Amount = 40,
                IdempotencyKey = idempotencyKey
            });
        }

        await using (var secondContext = db.CreateContext())
        {
            var service = StarsServiceTestFactory.Create(secondContext);

            // Simulates a client retry (e.g. after a dropped response) reusing the same key.
            second = await service.TransferAsync(senderId, new TransferStarsRequest
            {
                RecipientUserId = recipientId,
                Amount = 40,
                IdempotencyKey = idempotencyKey
            });
        }

        Assert.Equal(first.Balance, second.Balance);
        Assert.Equal(60, second.Balance);

        await using (var assertContext = db.CreateContext())
        {
            var senderAfter = await assertContext.Users.FirstAsync(u => u.Id == senderId);
            var recipientAfter = await assertContext.Users.FirstAsync(u => u.Id == recipientId);

            Assert.Equal(60, senderAfter.StarsBalance);
            Assert.Equal(40, recipientAfter.StarsBalance);

            Assert.Equal(1, await assertContext.StarTransactions.CountAsync(t => t.UserId == senderId));
            Assert.Equal(1, await assertContext.StarTransactions.CountAsync(t => t.UserId == recipientId));
        }
    }
}
