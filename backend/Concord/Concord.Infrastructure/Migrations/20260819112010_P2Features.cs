using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Concord.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class P2Features : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:channel_type", "text,voice")
                .Annotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .Annotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_received,mention,missed_call")
                .Annotation("Npgsql:Enum:presence_status", "do_not_disturb,idle,invisible,offline,online")
                .Annotation("Npgsql:Enum:roles", "admin,user")
                .Annotation("Npgsql:PostgresExtension:pg_trgm", ",,")
                .OldAnnotation("Npgsql:Enum:channel_type", "text,voice")
                .OldAnnotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .OldAnnotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_received,missed_call")
                .OldAnnotation("Npgsql:Enum:presence_status", "do_not_disturb,idle,invisible,offline,online")
                .OldAnnotation("Npgsql:Enum:roles", "admin,user");

            migrationBuilder.AddColumn<string>(
                name: "ActivityApplicationName",
                table: "User",
                type: "character varying(128)",
                maxLength: 128,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ActivityStartedAt",
                table: "User",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ActivityType",
                table: "User",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ContextChannelId",
                table: "Notification",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ContextConversationId",
                table: "Notification",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ContextMessageId",
                table: "Notification",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ForwardedFromCreatedAt",
                table: "Message",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ForwardedFromSenderId",
                table: "Message",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "PinnedAt",
                table: "Message",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "PinnedByUserId",
                table: "Message",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ForwardedFromCreatedAt",
                table: "DirectMessage",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ForwardedFromSenderId",
                table: "DirectMessage",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "PinnedAt",
                table: "DirectMessage",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "PinnedByUserId",
                table: "DirectMessage",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "DirectMessageMention",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    DirectMessageId = table.Column<Guid>(type: "uuid", nullable: false),
                    MentionedUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Created = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DirectMessageMention", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DirectMessageMention_DirectMessage_DirectMessageId",
                        column: x => x.DirectMessageId,
                        principalTable: "DirectMessage",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_DirectMessageMention_User_MentionedUserId",
                        column: x => x.MentionedUserId,
                        principalTable: "User",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "MessageMention",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MessageId = table.Column<Guid>(type: "uuid", nullable: false),
                    MentionedUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Created = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MessageMention", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MessageMention_Message_MessageId",
                        column: x => x.MessageId,
                        principalTable: "Message",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MessageMention_User_MentionedUserId",
                        column: x => x.MentionedUserId,
                        principalTable: "User",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Notification_ContextChannelId",
                table: "Notification",
                column: "ContextChannelId");

            migrationBuilder.CreateIndex(
                name: "IX_Notification_ContextConversationId",
                table: "Notification",
                column: "ContextConversationId");

            migrationBuilder.CreateIndex(
                name: "IX_Message_Content",
                table: "Message",
                column: "Content")
                .Annotation("Npgsql:IndexMethod", "gin")
                .Annotation("Npgsql:IndexOperators", new[] { "gin_trgm_ops" });

            migrationBuilder.CreateIndex(
                name: "IX_Message_ForwardedFromSenderId",
                table: "Message",
                column: "ForwardedFromSenderId");

            migrationBuilder.CreateIndex(
                name: "IX_Message_PinnedByUserId",
                table: "Message",
                column: "PinnedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_DirectMessage_Content",
                table: "DirectMessage",
                column: "Content")
                .Annotation("Npgsql:IndexMethod", "gin")
                .Annotation("Npgsql:IndexOperators", new[] { "gin_trgm_ops" });

            migrationBuilder.CreateIndex(
                name: "IX_DirectMessage_ForwardedFromSenderId",
                table: "DirectMessage",
                column: "ForwardedFromSenderId");

            migrationBuilder.CreateIndex(
                name: "IX_DirectMessage_PinnedByUserId",
                table: "DirectMessage",
                column: "PinnedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_DirectMessageMention_DirectMessageId_MentionedUserId",
                table: "DirectMessageMention",
                columns: new[] { "DirectMessageId", "MentionedUserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DirectMessageMention_MentionedUserId",
                table: "DirectMessageMention",
                column: "MentionedUserId");

            migrationBuilder.CreateIndex(
                name: "IX_MessageMention_MentionedUserId",
                table: "MessageMention",
                column: "MentionedUserId");

            migrationBuilder.CreateIndex(
                name: "IX_MessageMention_MessageId_MentionedUserId",
                table: "MessageMention",
                columns: new[] { "MessageId", "MentionedUserId" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_DirectMessage_User_ForwardedFromSenderId",
                table: "DirectMessage",
                column: "ForwardedFromSenderId",
                principalTable: "User",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_DirectMessage_User_PinnedByUserId",
                table: "DirectMessage",
                column: "PinnedByUserId",
                principalTable: "User",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Message_User_ForwardedFromSenderId",
                table: "Message",
                column: "ForwardedFromSenderId",
                principalTable: "User",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Message_User_PinnedByUserId",
                table: "Message",
                column: "PinnedByUserId",
                principalTable: "User",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Notification_Channel_ContextChannelId",
                table: "Notification",
                column: "ContextChannelId",
                principalTable: "Channel",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Notification_Conversation_ContextConversationId",
                table: "Notification",
                column: "ContextConversationId",
                principalTable: "Conversation",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_DirectMessage_User_ForwardedFromSenderId",
                table: "DirectMessage");

            migrationBuilder.DropForeignKey(
                name: "FK_DirectMessage_User_PinnedByUserId",
                table: "DirectMessage");

            migrationBuilder.DropForeignKey(
                name: "FK_Message_User_ForwardedFromSenderId",
                table: "Message");

            migrationBuilder.DropForeignKey(
                name: "FK_Message_User_PinnedByUserId",
                table: "Message");

            migrationBuilder.DropForeignKey(
                name: "FK_Notification_Channel_ContextChannelId",
                table: "Notification");

            migrationBuilder.DropForeignKey(
                name: "FK_Notification_Conversation_ContextConversationId",
                table: "Notification");

            migrationBuilder.DropTable(
                name: "DirectMessageMention");

            migrationBuilder.DropTable(
                name: "MessageMention");

            migrationBuilder.DropIndex(
                name: "IX_Notification_ContextChannelId",
                table: "Notification");

            migrationBuilder.DropIndex(
                name: "IX_Notification_ContextConversationId",
                table: "Notification");

            migrationBuilder.DropIndex(
                name: "IX_Message_Content",
                table: "Message");

            migrationBuilder.DropIndex(
                name: "IX_Message_ForwardedFromSenderId",
                table: "Message");

            migrationBuilder.DropIndex(
                name: "IX_Message_PinnedByUserId",
                table: "Message");

            migrationBuilder.DropIndex(
                name: "IX_DirectMessage_Content",
                table: "DirectMessage");

            migrationBuilder.DropIndex(
                name: "IX_DirectMessage_ForwardedFromSenderId",
                table: "DirectMessage");

            migrationBuilder.DropIndex(
                name: "IX_DirectMessage_PinnedByUserId",
                table: "DirectMessage");

            migrationBuilder.DropColumn(
                name: "ActivityApplicationName",
                table: "User");

            migrationBuilder.DropColumn(
                name: "ActivityStartedAt",
                table: "User");

            migrationBuilder.DropColumn(
                name: "ActivityType",
                table: "User");

            migrationBuilder.DropColumn(
                name: "ContextChannelId",
                table: "Notification");

            migrationBuilder.DropColumn(
                name: "ContextConversationId",
                table: "Notification");

            migrationBuilder.DropColumn(
                name: "ContextMessageId",
                table: "Notification");

            migrationBuilder.DropColumn(
                name: "ForwardedFromCreatedAt",
                table: "Message");

            migrationBuilder.DropColumn(
                name: "ForwardedFromSenderId",
                table: "Message");

            migrationBuilder.DropColumn(
                name: "PinnedAt",
                table: "Message");

            migrationBuilder.DropColumn(
                name: "PinnedByUserId",
                table: "Message");

            migrationBuilder.DropColumn(
                name: "ForwardedFromCreatedAt",
                table: "DirectMessage");

            migrationBuilder.DropColumn(
                name: "ForwardedFromSenderId",
                table: "DirectMessage");

            migrationBuilder.DropColumn(
                name: "PinnedAt",
                table: "DirectMessage");

            migrationBuilder.DropColumn(
                name: "PinnedByUserId",
                table: "DirectMessage");

            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:channel_type", "text,voice")
                .Annotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .Annotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_received,missed_call")
                .Annotation("Npgsql:Enum:presence_status", "do_not_disturb,idle,invisible,offline,online")
                .Annotation("Npgsql:Enum:roles", "admin,user")
                .OldAnnotation("Npgsql:Enum:channel_type", "text,voice")
                .OldAnnotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .OldAnnotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_received,mention,missed_call")
                .OldAnnotation("Npgsql:Enum:presence_status", "do_not_disturb,idle,invisible,offline,online")
                .OldAnnotation("Npgsql:Enum:roles", "admin,user")
                .OldAnnotation("Npgsql:PostgresExtension:pg_trgm", ",,");
        }
    }
}
