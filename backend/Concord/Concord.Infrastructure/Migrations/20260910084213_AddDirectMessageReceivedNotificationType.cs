using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Concord.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDirectMessageReceivedNotificationType : Migration
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
                .Annotation("Npgsql:PostgresExtension:pg_trgm", ",,")
                .OldAnnotation("Npgsql:Enum:channel_type", "text,voice")
                .OldAnnotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .OldAnnotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_cancelled,friend_request_declined,friend_request_received,mention,missed_call")
                .OldAnnotation("Npgsql:Enum:presence_status", "do_not_disturb,idle,invisible,offline,online")
                .OldAnnotation("Npgsql:Enum:qr_login_status", "approved,consumed,denied,pending")
                .OldAnnotation("Npgsql:Enum:roles", "admin,user")
                .OldAnnotation("Npgsql:PostgresExtension:pg_trgm", ",,");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:channel_type", "text,voice")
                .Annotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .Annotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_cancelled,friend_request_declined,friend_request_received,mention,missed_call")
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
                .OldAnnotation("Npgsql:PostgresExtension:pg_trgm", ",,");
        }
    }
}
