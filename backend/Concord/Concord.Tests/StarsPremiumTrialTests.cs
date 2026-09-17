using Concord.Application.Enums;
using Concord.Application.Models;
using Concord.Domain.Entities;
using Concord.Domain.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace Concord.Tests;

/// <summary>See <see cref="StarsTransferTests"/>'s class remarks on why each test uses a separate
/// <see cref="Concord.Infrastructure.Context.ApplicationDbContext"/> per seed/act/assert phase.</summary>
public class StarsPremiumTrialTests
{
    [Fact]
    public async Task ActivatePremiumTrial_DebitsCorrectlyAndSetsExactly14DaysOut()
    {
        using var db = new TestDatabase();

        Guid userId;
        await using (var seed = db.CreateContext())
        {
            var user = StarsServiceTestFactory.CreateUser("trialuser");
            user.StarsBalance = 1000;

            seed.Users.Add(user);
            await seed.SaveChangesAsync();

            userId = user.Id;
        }

        var before = DateTime.UtcNow;
        ActivatePremiumTrialResponse response;

        await using (var actContext = db.CreateContext())
        {
            var service = StarsServiceTestFactory.Create(actContext);

            response = await service.ActivatePremiumTrialAsync(userId, new ActivatePremiumTrialRequest
            {
                IdempotencyKey = Guid.NewGuid().ToString()
            });
        }

        var after = DateTime.UtcNow;

        Assert.Equal(1000 - StarsConstants.PremiumTrialCostStars, response.Balance);

        var expectedMin = before.AddDays(StarsConstants.PremiumTrialDurationDays);
        var expectedMax = after.AddDays(StarsConstants.PremiumTrialDurationDays);

        Assert.InRange(response.PremiumTrialExpiresAt, expectedMin, expectedMax);

        await using (var assertContext = db.CreateContext())
        {
            var userAfter = await assertContext.Users.FirstAsync(u => u.Id == userId);
            Assert.Equal(1000 - StarsConstants.PremiumTrialCostStars, userAfter.StarsBalance);
            Assert.Equal(response.PremiumTrialExpiresAt, userAfter.PremiumTrialExpiresAt);

            var ledgerRow = await assertContext.StarTransactions.SingleAsync(t => t.UserId == userId);
            Assert.Equal(StarTransactionType.PremiumTrialPurchase, ledgerRow.Type);
            Assert.Equal(-StarsConstants.PremiumTrialCostStars, ledgerRow.Amount);
            Assert.Equal(userAfter.StarsBalance, ledgerRow.BalanceAfter);
        }
    }

    [Fact]
    public async Task ActivatePremiumTrial_WhileAlreadyActive_Throws()
    {
        using var db = new TestDatabase();

        Guid userId;
        await using (var seed = db.CreateContext())
        {
            var user = StarsServiceTestFactory.CreateUser("alreadytrialing");
            user.StarsBalance = 1000;
            user.PremiumTrialExpiresAt = DateTime.UtcNow.AddDays(5);

            seed.Users.Add(user);
            await seed.SaveChangesAsync();

            userId = user.Id;
        }

        await using (var actContext = db.CreateContext())
        {
            var service = StarsServiceTestFactory.Create(actContext);

            await Assert.ThrowsAsync<PremiumTrialAlreadyActiveException>(() => service.ActivatePremiumTrialAsync(userId, new ActivatePremiumTrialRequest
            {
                IdempotencyKey = Guid.NewGuid().ToString()
            }));
        }

        await using (var assertContext = db.CreateContext())
        {
            var userAfter = await assertContext.Users.FirstAsync(u => u.Id == userId);
            Assert.Equal(1000, userAfter.StarsBalance);
        }
    }

    [Fact]
    public async Task ActivatePremiumTrial_InsufficientBalance_Throws()
    {
        using var db = new TestDatabase();

        Guid userId;
        await using (var seed = db.CreateContext())
        {
            var user = StarsServiceTestFactory.CreateUser("poortrial");
            user.StarsBalance = StarsConstants.PremiumTrialCostStars - 1;

            seed.Users.Add(user);
            await seed.SaveChangesAsync();

            userId = user.Id;
        }

        await using (var actContext = db.CreateContext())
        {
            var service = StarsServiceTestFactory.Create(actContext);

            await Assert.ThrowsAsync<InsufficientStarsBalanceException>(() => service.ActivatePremiumTrialAsync(userId, new ActivatePremiumTrialRequest
            {
                IdempotencyKey = Guid.NewGuid().ToString()
            }));
        }

        await using (var assertContext = db.CreateContext())
        {
            var userAfter = await assertContext.Users.FirstAsync(u => u.Id == userId);
            Assert.Equal(StarsConstants.PremiumTrialCostStars - 1, userAfter.StarsBalance);
            Assert.Null(userAfter.PremiumTrialExpiresAt);
        }
    }

    [Fact]
    public async Task ActivatePremiumTrial_WhilePayingSubscriber_Throws()
    {
        using var db = new TestDatabase();

        Guid userId;
        await using (var seed = db.CreateContext())
        {
            var user = StarsServiceTestFactory.CreateUser("payinguser");
            user.StarsBalance = 1000;

            seed.Users.Add(user);

            seed.Subscriptions.Add(new Subscription
            {
                UserId = user.Id,
                StripeCustomerId = "cus_fake",
                StripeSubscriptionId = "sub_fake",
                Status = SubscriptionStatus.Active,
                CurrentPeriodEnd = DateTime.UtcNow.AddDays(20)
            });

            await seed.SaveChangesAsync();

            userId = user.Id;
        }

        await using (var actContext = db.CreateContext())
        {
            var service = StarsServiceTestFactory.Create(actContext);

            await Assert.ThrowsAsync<PremiumTrialAlreadyActiveException>(() => service.ActivatePremiumTrialAsync(userId, new ActivatePremiumTrialRequest
            {
                IdempotencyKey = Guid.NewGuid().ToString()
            }));
        }

        await using (var assertContext = db.CreateContext())
        {
            var userAfter = await assertContext.Users.FirstAsync(u => u.Id == userId);
            Assert.Equal(1000, userAfter.StarsBalance);
        }
    }
}
