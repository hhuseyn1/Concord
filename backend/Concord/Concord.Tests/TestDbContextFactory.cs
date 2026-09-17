using Concord.Infrastructure.Context;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;

namespace Concord.Tests;

/// <summary>
/// Builds real <see cref="ApplicationDbContext"/> instances against a Sqlite in-memory database
/// rather than mocking EF Core, per the project's testing convention. A single open
/// <see cref="SqliteConnection"/> is shared by every <see cref="ApplicationDbContext"/> created from
/// the same <see cref="TestDatabase"/> instance (closing the connection is what destroys an
/// in-memory Sqlite database, and each DbContext otherwise opens/closes its own connection) - this
/// is also what lets the concurrency test use two independent DbContext instances against the same
/// underlying data, the same way two ASP.NET Core requests would each get their own scoped context
/// against the same real Postgres database.
///
/// ApplicationDbContext.OnModelCreating uses a few Postgres-only constructs (HasDefaultValueSql
/// ("now()"), the pg_trgm extension/gin indexes) that Sqlite doesn't natively understand:
/// - "now()" is handled by registering a matching Sqlite scalar function of the same name below,
///   so server-generated Created/BalanceAfter-style timestamps still work without touching
///   production model configuration.
/// - The pg_trgm extension and gin index method/operators are silently ignored by Sqlite's schema
///   generator (they're Npgsql-specific annotations), which is fine for tests that never search by
///   Content.
/// </summary>
public sealed class TestDatabase : IDisposable
{
    private readonly SqliteConnection _connection;

    public TestDatabase()
    {
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        // Postgres-specific default value SQL used throughout ApplicationDbContext
        // (HasDefaultValueSql("now()")) - registering a same-named Sqlite scalar function makes it
        // resolve the same way it would against real Postgres, without editing production model
        // configuration for the sake of tests.
        _connection.CreateFunction("now", () => DateTime.UtcNow);

        using var context = CreateContext();
        context.Database.EnsureCreated();
    }

    public ApplicationDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseSqlite(_connection)
            .Options;

        return new ApplicationDbContext(options);
    }

    public void Dispose()
    {
        _connection.Dispose();
    }
}
