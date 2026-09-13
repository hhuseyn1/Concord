using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Concord.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddReportDismissedNotification : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:channel_type", "text,voice")
                .Annotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .Annotation("Npgsql:Enum:notification_type", "direct_message_received,friend_request_accepted,friend_request_cancelled,friend_request_declined,friend_request_received,mention,missed_call,report_dismissed")
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
                .OldAnnotation("Npgsql:Enum:subscription_status", "active,canceled,past_due")
                .OldAnnotation("Npgsql:PostgresExtension:pg_trgm", ",,");

            migrationBuilder.AddColumn<string>(
                name: "Reason",
                table: "Notification",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Reason",
                table: "Notification");

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
                .OldAnnotation("Npgsql:Enum:notification_type", "direct_message_received,friend_request_accepted,friend_request_cancelled,friend_request_declined,friend_request_received,mention,missed_call,report_dismissed")
                .OldAnnotation("Npgsql:Enum:presence_status", "do_not_disturb,idle,invisible,offline,online")
                .OldAnnotation("Npgsql:Enum:qr_login_status", "approved,consumed,denied,pending")
                .OldAnnotation("Npgsql:Enum:roles", "admin,user")
                .OldAnnotation("Npgsql:Enum:subscription_status", "active,canceled,past_due")
                .OldAnnotation("Npgsql:PostgresExtension:pg_trgm", ",,");
        }
    }
}
