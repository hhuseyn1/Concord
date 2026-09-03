using System;
using Concord.Application.Enums;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Concord.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddUserPresence : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:channel_type", "text,voice")
                .Annotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .Annotation("Npgsql:Enum:presence_status", "idle,offline,online")
                .Annotation("Npgsql:Enum:roles", "admin,user")
                .OldAnnotation("Npgsql:Enum:channel_type", "text,voice")
                .OldAnnotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .OldAnnotation("Npgsql:Enum:roles", "admin,user");

            migrationBuilder.CreateTable(
                name: "UserPresence",
                columns: table => new
                {
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<PresenceStatus>(type: "presence_status", nullable: false),
                    LastSeenAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Created = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserPresence", x => x.UserId);
                    table.ForeignKey(
                        name: "FK_UserPresence_User_UserId",
                        column: x => x.UserId,
                        principalTable: "User",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "UserPresence");

            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:channel_type", "text,voice")
                .Annotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .Annotation("Npgsql:Enum:roles", "admin,user")
                .OldAnnotation("Npgsql:Enum:channel_type", "text,voice")
                .OldAnnotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .OldAnnotation("Npgsql:Enum:presence_status", "idle,offline,online")
                .OldAnnotation("Npgsql:Enum:roles", "admin,user");
        }
    }
}
