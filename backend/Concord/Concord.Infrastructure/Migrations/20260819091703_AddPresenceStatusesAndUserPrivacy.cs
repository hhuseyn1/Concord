using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Concord.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddPresenceStatusesAndUserPrivacy : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:channel_type", "text,voice")
                .Annotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .Annotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_received,missed_call")
                .Annotation("Npgsql:Enum:presence_status", "do_not_disturb,idle,invisible,offline,online")
                .Annotation("Npgsql:Enum:roles", "admin,user")
                .OldAnnotation("Npgsql:Enum:channel_type", "text,voice")
                .OldAnnotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .OldAnnotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_received,missed_call")
                .OldAnnotation("Npgsql:Enum:presence_status", "idle,offline,online")
                .OldAnnotation("Npgsql:Enum:roles", "admin,user");

            migrationBuilder.AddColumn<int>(
                name: "ActivityVisibility",
                table: "User",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "CustomStatusEmoji",
                table: "User",
                type: "character varying(16)",
                maxLength: 16,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CustomStatusExpiresAt",
                table: "User",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CustomStatusText",
                table: "User",
                type: "character varying(128)",
                maxLength: 128,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "DirectMessagePrivacy",
                table: "User",
                type: "integer",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "FriendRequestPrivacy",
                table: "User",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<bool>(
                name: "ReadReceiptsEnabled",
                table: "User",
                type: "boolean",
                nullable: false,
                defaultValue: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ActivityVisibility",
                table: "User");

            migrationBuilder.DropColumn(
                name: "CustomStatusEmoji",
                table: "User");

            migrationBuilder.DropColumn(
                name: "CustomStatusExpiresAt",
                table: "User");

            migrationBuilder.DropColumn(
                name: "CustomStatusText",
                table: "User");

            migrationBuilder.DropColumn(
                name: "DirectMessagePrivacy",
                table: "User");

            migrationBuilder.DropColumn(
                name: "FriendRequestPrivacy",
                table: "User");

            migrationBuilder.DropColumn(
                name: "ReadReceiptsEnabled",
                table: "User");

            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:channel_type", "text,voice")
                .Annotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .Annotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_received,missed_call")
                .Annotation("Npgsql:Enum:presence_status", "idle,offline,online")
                .Annotation("Npgsql:Enum:roles", "admin,user")
                .OldAnnotation("Npgsql:Enum:channel_type", "text,voice")
                .OldAnnotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .OldAnnotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_received,missed_call")
                .OldAnnotation("Npgsql:Enum:presence_status", "do_not_disturb,idle,invisible,offline,online")
                .OldAnnotation("Npgsql:Enum:roles", "admin,user");
        }
    }
}
