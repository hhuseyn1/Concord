using System;
using Concord.Application.Enums;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Concord.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddQrLogin : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:channel_type", "text,voice")
                .Annotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .Annotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_received,mention,missed_call")
                .Annotation("Npgsql:Enum:presence_status", "do_not_disturb,idle,invisible,offline,online")
                .Annotation("Npgsql:Enum:qr_login_status", "approved,consumed,denied,pending")
                .Annotation("Npgsql:Enum:roles", "admin,user")
                .Annotation("Npgsql:PostgresExtension:pg_trgm", ",,")
                .OldAnnotation("Npgsql:Enum:channel_type", "text,voice")
                .OldAnnotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .OldAnnotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_received,mention,missed_call")
                .OldAnnotation("Npgsql:Enum:presence_status", "do_not_disturb,idle,invisible,offline,online")
                .OldAnnotation("Npgsql:Enum:roles", "admin,user")
                .OldAnnotation("Npgsql:PostgresExtension:pg_trgm", ",,");

            migrationBuilder.CreateTable(
                name: "QrLoginSession",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserCode = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    PollingTokenHash = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    Status = table.Column<QrLoginStatus>(type: "qr_login_status", nullable: false),
                    ApprovedByUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    ExpiresAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ConsumedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    UserAgent = table.Column<string>(type: "character varying(512)", maxLength: 512, nullable: true),
                    IpAddress = table.Column<string>(type: "character varying(45)", maxLength: 45, nullable: true),
                    DeviceLabel = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Browser = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    OS = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Created = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_QrLoginSession", x => x.Id);
                    table.ForeignKey(
                        name: "FK_QrLoginSession_User_ApprovedByUserId",
                        column: x => x.ApprovedByUserId,
                        principalTable: "User",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_QrLoginSession_ApprovedByUserId",
                table: "QrLoginSession",
                column: "ApprovedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_QrLoginSession_PollingTokenHash",
                table: "QrLoginSession",
                column: "PollingTokenHash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_QrLoginSession_UserCode",
                table: "QrLoginSession",
                column: "UserCode",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "QrLoginSession");

            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:channel_type", "text,voice")
                .Annotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .Annotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_received,mention,missed_call")
                .Annotation("Npgsql:Enum:presence_status", "do_not_disturb,idle,invisible,offline,online")
                .Annotation("Npgsql:Enum:roles", "admin,user")
                .Annotation("Npgsql:PostgresExtension:pg_trgm", ",,")
                .OldAnnotation("Npgsql:Enum:channel_type", "text,voice")
                .OldAnnotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .OldAnnotation("Npgsql:Enum:notification_type", "friend_request_accepted,friend_request_received,mention,missed_call")
                .OldAnnotation("Npgsql:Enum:presence_status", "do_not_disturb,idle,invisible,offline,online")
                .OldAnnotation("Npgsql:Enum:qr_login_status", "approved,consumed,denied,pending")
                .OldAnnotation("Npgsql:Enum:roles", "admin,user")
                .OldAnnotation("Npgsql:PostgresExtension:pg_trgm", ",,");
        }
    }
}
