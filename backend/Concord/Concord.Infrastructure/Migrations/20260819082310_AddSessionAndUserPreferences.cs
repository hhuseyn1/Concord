using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Concord.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSessionAndUserPreferences : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:channel_type", "text,voice")
                .Annotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .Annotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_received,missed_call")
                .Annotation("Npgsql:Enum:presence_status", "idle,offline,online")
                .Annotation("Npgsql:Enum:roles", "admin,user")
                .OldAnnotation("Npgsql:Enum:channel_type", "text,voice")
                .OldAnnotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .OldAnnotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_received")
                .OldAnnotation("Npgsql:Enum:presence_status", "idle,offline,online")
                .OldAnnotation("Npgsql:Enum:roles", "admin,user");

            migrationBuilder.AddColumn<bool>(
                name: "NotificationsMuted",
                table: "User",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "NotificationsSoundEnabled",
                table: "User",
                type: "boolean",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddColumn<string>(
                name: "Browser",
                table: "Session",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "DeviceLabel",
                table: "Session",
                type: "character varying(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "IpAddress",
                table: "Session",
                type: "character varying(45)",
                maxLength: 45,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "OS",
                table: "Session",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "UserAgent",
                table: "Session",
                type: "character varying(512)",
                maxLength: 512,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Call",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ConversationId = table.Column<Guid>(type: "uuid", nullable: false),
                    InitiatorId = table.Column<Guid>(type: "uuid", nullable: false),
                    CalleeId = table.Column<Guid>(type: "uuid", nullable: false),
                    Type = table.Column<int>(type: "integer", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    AnsweredAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    EndedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Created = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Call", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Call_Conversation_ConversationId",
                        column: x => x.ConversationId,
                        principalTable: "Conversation",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Call_User_CalleeId",
                        column: x => x.CalleeId,
                        principalTable: "User",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Call_User_InitiatorId",
                        column: x => x.InitiatorId,
                        principalTable: "User",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Call_CalleeId",
                table: "Call",
                column: "CalleeId");

            migrationBuilder.CreateIndex(
                name: "IX_Call_ConversationId",
                table: "Call",
                column: "ConversationId");

            migrationBuilder.CreateIndex(
                name: "IX_Call_InitiatorId",
                table: "Call",
                column: "InitiatorId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Call");

            migrationBuilder.DropColumn(
                name: "NotificationsMuted",
                table: "User");

            migrationBuilder.DropColumn(
                name: "NotificationsSoundEnabled",
                table: "User");

            migrationBuilder.DropColumn(
                name: "Browser",
                table: "Session");

            migrationBuilder.DropColumn(
                name: "DeviceLabel",
                table: "Session");

            migrationBuilder.DropColumn(
                name: "IpAddress",
                table: "Session");

            migrationBuilder.DropColumn(
                name: "OS",
                table: "Session");

            migrationBuilder.DropColumn(
                name: "UserAgent",
                table: "Session");

            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:channel_type", "text,voice")
                .Annotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .Annotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_received")
                .Annotation("Npgsql:Enum:presence_status", "idle,offline,online")
                .Annotation("Npgsql:Enum:roles", "admin,user")
                .OldAnnotation("Npgsql:Enum:channel_type", "text,voice")
                .OldAnnotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .OldAnnotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_received,missed_call")
                .OldAnnotation("Npgsql:Enum:presence_status", "idle,offline,online")
                .OldAnnotation("Npgsql:Enum:roles", "admin,user");
        }
    }
}
