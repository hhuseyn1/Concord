using Concord.Domain.Entities;
using Concord.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Concord.Tests;

public class SmokeTests
{
    [Fact]
    public async Task CanCreateSchemaAndInsertUser()
    {
        using var db = new TestDatabase();
        await using var context = db.CreateContext();

        var user = new User("test@example.com", "hash", null, "en-EN", Roles.User, "Test", "User")
        {
            Username = "testuser"
        };

        context.Users.Add(user);
        await context.SaveChangesAsync();

        var fetched = await context.Users.FirstOrDefaultAsync(u => u.Id == user.Id);

        Assert.NotNull(fetched);
        Assert.Equal(0, fetched!.StarsBalance);
        Assert.True(fetched.Created > DateTime.MinValue);
    }
}
