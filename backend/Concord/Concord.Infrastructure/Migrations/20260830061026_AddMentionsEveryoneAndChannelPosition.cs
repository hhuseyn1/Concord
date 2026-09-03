using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Concord.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddMentionsEveryoneAndChannelPosition : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Channel_ServerId",
                table: "Channel");

            migrationBuilder.AddColumn<bool>(
                name: "MentionsEveryone",
                table: "Message",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "Position",
                table: "Channel",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            // Backfill: every pre-existing channel would otherwise land on the column default of 0,
            // which makes every channel within a ServerId/Type group tie and leaves their relative
            // order undefined against each other (ChannelsService.GetChannelsForServerAsync now
            // orders by Position within each group). Assigns 0-based positions by current creation
            // order (Created, then Id to break exact ties) instead, which is behaviour-preserving -
            // it reproduces the implicit "OrderBy(Created)" every client already saw before this
            // migration.
            migrationBuilder.Sql("""
                WITH ranked AS (
                    SELECT "Id", ROW_NUMBER() OVER (PARTITION BY "ServerId", "Type" ORDER BY "Created", "Id") - 1 AS "NewPosition"
                    FROM "Channel"
                )
                UPDATE "Channel"
                SET "Position" = ranked."NewPosition"
                FROM ranked
                WHERE "Channel"."Id" = ranked."Id";
                """);

            migrationBuilder.CreateIndex(
                name: "IX_Channel_ServerId_Type_Position",
                table: "Channel",
                columns: new[] { "ServerId", "Type", "Position" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Channel_ServerId_Type_Position",
                table: "Channel");

            migrationBuilder.DropColumn(
                name: "MentionsEveryone",
                table: "Message");

            migrationBuilder.DropColumn(
                name: "Position",
                table: "Channel");

            migrationBuilder.CreateIndex(
                name: "IX_Channel_ServerId",
                table: "Channel",
                column: "ServerId");
        }
    }
}
