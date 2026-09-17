using Concord.Domain.Entities;
using Concord.Domain.Enums;
using Concord.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;

namespace Concord.Infrastructure.Context;

public static class DbSeeder
{
    public static async Task SeedAsync(ApplicationDbContext context)
    {
        if (await context.Users.AnyAsync())
            return;

        var adminPassword = PasswordHasher.HashPassword("admin");
        var admin = new User("admin@gmail.com", adminPassword, "994773911322", "az-AZ", Roles.Admin, "Admin", "Admin");
        context.Users.Add(admin);

        await context.SaveChangesAsync();
    }
}
