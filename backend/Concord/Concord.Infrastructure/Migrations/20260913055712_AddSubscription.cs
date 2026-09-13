using System;
using Concord.Application.Enums;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Concord.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSubscription : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:channel_type", "text,voice")
                .Annotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .Annotation("Npgsql:Enum:notification_type", "direct_message_received,friend_request_accepted,friend_request_cancelled,friend_request_declined,friend_request_received,mention,missed_call")
                .Annotation("Npgsql:Enum:presence_status", "do_not_disturb,idle,invisible,offline,online")
                .Annotation("Npgsql:Enum:qr_login_status", "approved,consumed,denied,pending")
                .Annotation("Npgsql:Enum:roles", "admin,user")
                .Annotation("Npgsql:Enum:subscription_status", "active,canceled,past_due")
                .Annotation("Npgsql:PostgresExtension:pg_trgm", ",,")
                .OldAnnotation("Npgsql:Enum:channel_type", "text,voice")
                .OldAnnotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .OldAnnotation("Npgsql:Enum:notification_type", "direct_message_received,friend_request_accepted,friend_request_cancelled,friend_request_declined,friend_request_received,mention,missed_call")
                .OldAnnotation("Npgsql:Enum:presence_status", "do_not_disturb,idle,invisible,offline,online")
                .OldAnnotation("Npgsql:Enum:qr_login_status", "approved,consumed,denied,pending")
                .OldAnnotation("Npgsql:Enum:roles", "admin,user")
                .OldAnnotation("Npgsql:PostgresExtension:pg_trgm", ",,");

            migrationBuilder.CreateTable(
                name: "Subscription",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    StripeCustomerId = table.Column<string>(type: "text", nullable: false),
                    StripeSubscriptionId = table.Column<string>(type: "text", nullable: false),
                    Status = table.Column<SubscriptionStatus>(type: "subscription_status", nullable: false),
                    CurrentPeriodEnd = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CancelAtPeriodEnd = table.Column<bool>(type: "boolean", nullable: false),
                    Created = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Subscription", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Subscription_User_UserId",
                        column: x => x.UserId,
                        principalTable: "User",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Subscription_StripeSubscriptionId",
                table: "Subscription",
                column: "StripeSubscriptionId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Subscription_UserId",
                table: "Subscription",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Subscription");

            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:channel_type", "text,voice")
                .Annotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .Annotation("Npgsql:Enum:notification_type", "direct_message_received,friend_request_accepted,friend_request_cancelled,friend_request_declined,friend_request_received,mention,missed_call")
                .Annotation("Npgsql:Enum:presence_status", "do_not_disturb,idle,invisible,offline,online")
                .Annotation("Npgsql:Enum:qr_login_status", "approved,consumed,denied,pending")
                .Annotation("Npgsql:Enum:roles", "admin,user")
                .Annotation("Npgsql:PostgresExtension:pg_trgm", ",,")
                .OldAnnotation("Npgsql:Enum:channel_type", "text,voice")
                .OldAnnotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .OldAnnotation("Npgsql:Enum:notification_type", "direct_message_received,friend_request_accepted,friend_request_cancelled,friend_request_declined,friend_request_received,mention,missed_call")
                .OldAnnotation("Npgsql:Enum:presence_status", "do_not_disturb,idle,invisible,offline,online")
                .OldAnnotation("Npgsql:Enum:qr_login_status", "approved,consumed,denied,pending")
                .OldAnnotation("Npgsql:Enum:roles", "admin,user")
                .OldAnnotation("Npgsql:Enum:subscription_status", "active,canceled,past_due")
                .OldAnnotation("Npgsql:PostgresExtension:pg_trgm", ",,");
        }
    }
}
