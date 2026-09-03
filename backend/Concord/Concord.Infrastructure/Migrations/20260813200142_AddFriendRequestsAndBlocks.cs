using System;
using Concord.Application.Enums;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Concord.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddFriendRequestsAndBlocks : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .Annotation("Npgsql:Enum:roles", "admin,user")
                .OldAnnotation("Npgsql:Enum:roles", "admin,user");

            migrationBuilder.CreateTable(
                name: "Block",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BlockerId = table.Column<Guid>(type: "uuid", nullable: false),
                    BlockedId = table.Column<Guid>(type: "uuid", nullable: false),
                    Created = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Block", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Block_User_BlockedId",
                        column: x => x.BlockedId,
                        principalTable: "User",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Block_User_BlockerId",
                        column: x => x.BlockerId,
                        principalTable: "User",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "FriendRequest",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    RequesterId = table.Column<Guid>(type: "uuid", nullable: false),
                    AddresseeId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<FriendRequestStatus>(type: "friend_request_status", nullable: false),
                    Created = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FriendRequest", x => x.Id);
                    table.ForeignKey(
                        name: "FK_FriendRequest_User_AddresseeId",
                        column: x => x.AddresseeId,
                        principalTable: "User",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_FriendRequest_User_RequesterId",
                        column: x => x.RequesterId,
                        principalTable: "User",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Block_BlockedId",
                table: "Block",
                column: "BlockedId");

            migrationBuilder.CreateIndex(
                name: "IX_Block_BlockerId",
                table: "Block",
                column: "BlockerId");

            migrationBuilder.CreateIndex(
                name: "IX_FriendRequest_AddresseeId",
                table: "FriendRequest",
                column: "AddresseeId");

            migrationBuilder.CreateIndex(
                name: "IX_FriendRequest_RequesterId",
                table: "FriendRequest",
                column: "RequesterId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Block");

            migrationBuilder.DropTable(
                name: "FriendRequest");

            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:roles", "admin,user")
                .OldAnnotation("Npgsql:Enum:friend_request_status", "accepted,pending")
                .OldAnnotation("Npgsql:Enum:roles", "admin,user");
        }
    }
}
