using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Concord.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddMessageReplyTo : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ReplyToMessageId",
                table: "Message",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ReplyToMessageId",
                table: "DirectMessage",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Message_ReplyToMessageId",
                table: "Message",
                column: "ReplyToMessageId");

            migrationBuilder.CreateIndex(
                name: "IX_DirectMessage_ReplyToMessageId",
                table: "DirectMessage",
                column: "ReplyToMessageId");

            migrationBuilder.AddForeignKey(
                name: "FK_DirectMessage_DirectMessage_ReplyToMessageId",
                table: "DirectMessage",
                column: "ReplyToMessageId",
                principalTable: "DirectMessage",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Message_Message_ReplyToMessageId",
                table: "Message",
                column: "ReplyToMessageId",
                principalTable: "Message",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_DirectMessage_DirectMessage_ReplyToMessageId",
                table: "DirectMessage");

            migrationBuilder.DropForeignKey(
                name: "FK_Message_Message_ReplyToMessageId",
                table: "Message");

            migrationBuilder.DropIndex(
                name: "IX_Message_ReplyToMessageId",
                table: "Message");

            migrationBuilder.DropIndex(
                name: "IX_DirectMessage_ReplyToMessageId",
                table: "DirectMessage");

            migrationBuilder.DropColumn(
                name: "ReplyToMessageId",
                table: "Message");

            migrationBuilder.DropColumn(
                name: "ReplyToMessageId",
                table: "DirectMessage");
        }
    }
}
