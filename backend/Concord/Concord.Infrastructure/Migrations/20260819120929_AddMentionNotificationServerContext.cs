using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Concord.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddMentionNotificationServerContext : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ContextServerId",
                table: "Notification",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Notification_ContextServerId",
                table: "Notification",
                column: "ContextServerId");

            migrationBuilder.AddForeignKey(
                name: "FK_Notification_Server_ContextServerId",
                table: "Notification",
                column: "ContextServerId",
                principalTable: "Server",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Notification_Server_ContextServerId",
                table: "Notification");

            migrationBuilder.DropIndex(
                name: "IX_Notification_ContextServerId",
                table: "Notification");

            migrationBuilder.DropColumn(
                name: "ContextServerId",
                table: "Notification");
        }
    }
}
