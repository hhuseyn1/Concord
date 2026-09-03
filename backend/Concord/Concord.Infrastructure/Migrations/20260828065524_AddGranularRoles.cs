using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Concord.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddGranularRoles : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Role",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ServerId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Color = table.Column<string>(type: "character varying(7)", maxLength: 7, nullable: true),
                    Permissions = table.Column<long>(type: "bigint", nullable: false),
                    Position = table.Column<int>(type: "integer", nullable: false),
                    IsDefault = table.Column<bool>(type: "boolean", nullable: false),
                    Created = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Role", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Role_Server_ServerId",
                        column: x => x.ServerId,
                        principalTable: "Server",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ServerMemberRole",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ServerMemberId = table.Column<Guid>(type: "uuid", nullable: false),
                    RoleId = table.Column<Guid>(type: "uuid", nullable: false),
                    Created = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServerMemberRole", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ServerMemberRole_Role_RoleId",
                        column: x => x.RoleId,
                        principalTable: "Role",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ServerMemberRole_ServerMember_ServerMemberId",
                        column: x => x.ServerMemberId,
                        principalTable: "ServerMember",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Role_ServerId_Default",
                table: "Role",
                column: "ServerId",
                unique: true,
                filter: "\"IsDefault\"");

            migrationBuilder.CreateIndex(
                name: "IX_Role_ServerId_Position",
                table: "Role",
                columns: new[] { "ServerId", "Position" });

            migrationBuilder.CreateIndex(
                name: "IX_ServerMemberRole_RoleId",
                table: "ServerMemberRole",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "IX_ServerMemberRole_ServerMemberId_RoleId",
                table: "ServerMemberRole",
                columns: new[] { "ServerMemberId", "RoleId" },
                unique: true);

            // Backfill: every pre-existing server needs its @everyone role, because
            // PermissionService reads that role as the baseline for every non-owner. Without this,
            // existing members would resolve to zero permissions and lose access to servers they
            // are already in.
            //
            // 6147 = ViewChannels (1) | SendMessages (2) | Connect (2048) | Speak (4096), which is
            // exactly what every member could do under the previous owner/member split - so the
            // migration is behaviour-preserving. Kept as a literal rather than a reference to
            // Role.DefaultRolePermissions so that editing the constant later cannot retroactively
            // change what this migration did.
            migrationBuilder.Sql("""
                INSERT INTO "Role" ("Id", "ServerId", "Name", "Color", "Permissions", "Position", "IsDefault", "Created")
                SELECT gen_random_uuid(), server."Id", '@everyone', NULL, 6147, 0, TRUE, now()
                FROM "Server" AS server
                WHERE NOT EXISTS (
                    SELECT 1 FROM "Role" AS role WHERE role."ServerId" = server."Id" AND role."IsDefault"
                );
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ServerMemberRole");

            migrationBuilder.DropTable(
                name: "Role");
        }
    }
}
