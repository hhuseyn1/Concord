using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Concord.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddStarsSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "LastStarRewardAt",
                table: "User",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "PremiumTrialExpiresAt",
                table: "User",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "StarsBalance",
                table: "User",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "StarsEarnedToday",
                table: "User",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateOnly>(
                name: "StarsEarnedTodayDate",
                table: "User",
                type: "date",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "StarPurchase",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    PackageId = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    StarsGranted = table.Column<int>(type: "integer", nullable: false),
                    PriceAmount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    Currency = table.Column<string>(type: "character varying(8)", maxLength: 8, nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    PaymentProvider = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    StripeCheckoutSessionId = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    StripePaymentIntentId = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Created = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StarPurchase", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StarPurchase_User_UserId",
                        column: x => x.UserId,
                        principalTable: "User",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "StarTransaction",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Type = table.Column<int>(type: "integer", nullable: false),
                    Amount = table.Column<int>(type: "integer", nullable: false),
                    BalanceAfter = table.Column<int>(type: "integer", nullable: false),
                    CounterpartyUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    RelatedPurchaseId = table.Column<Guid>(type: "uuid", nullable: true),
                    IdempotencyKey = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Created = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StarTransaction", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StarTransaction_StarPurchase_RelatedPurchaseId",
                        column: x => x.RelatedPurchaseId,
                        principalTable: "StarPurchase",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_StarTransaction_User_CounterpartyUserId",
                        column: x => x.CounterpartyUserId,
                        principalTable: "User",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_StarTransaction_User_UserId",
                        column: x => x.UserId,
                        principalTable: "User",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_StarPurchase_StripeCheckoutSessionId",
                table: "StarPurchase",
                column: "StripeCheckoutSessionId");

            migrationBuilder.CreateIndex(
                name: "IX_StarPurchase_UserId",
                table: "StarPurchase",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_StarTransaction_CounterpartyUserId",
                table: "StarTransaction",
                column: "CounterpartyUserId");

            migrationBuilder.CreateIndex(
                name: "IX_StarTransaction_RelatedPurchaseId",
                table: "StarTransaction",
                column: "RelatedPurchaseId");

            migrationBuilder.CreateIndex(
                name: "IX_StarTransaction_UserId_Created",
                table: "StarTransaction",
                columns: new[] { "UserId", "Created" });

            migrationBuilder.CreateIndex(
                name: "IX_StarTransaction_UserId_IdempotencyKey",
                table: "StarTransaction",
                columns: new[] { "UserId", "IdempotencyKey" },
                unique: true,
                filter: "\"IdempotencyKey\" IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "StarTransaction");

            migrationBuilder.DropTable(
                name: "StarPurchase");

            migrationBuilder.DropColumn(
                name: "LastStarRewardAt",
                table: "User");

            migrationBuilder.DropColumn(
                name: "PremiumTrialExpiresAt",
                table: "User");

            migrationBuilder.DropColumn(
                name: "StarsBalance",
                table: "User");

            migrationBuilder.DropColumn(
                name: "StarsEarnedToday",
                table: "User");

            migrationBuilder.DropColumn(
                name: "StarsEarnedTodayDate",
                table: "User");
        }
    }
}
