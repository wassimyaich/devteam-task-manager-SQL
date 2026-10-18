using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DevTeamTaskManager.Api.Migrations
{
    /// <inheritdoc />
    public partial class RestrictDeveloperTaskDeletion : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Tasks_Developers_AssigneeId",
                table: "Tasks");

            migrationBuilder.AddForeignKey(
                name: "FK_Tasks_Developers_AssigneeId",
                table: "Tasks",
                column: "AssigneeId",
                principalTable: "Developers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Tasks_Developers_AssigneeId",
                table: "Tasks");

            migrationBuilder.AddForeignKey(
                name: "FK_Tasks_Developers_AssigneeId",
                table: "Tasks",
                column: "AssigneeId",
                principalTable: "Developers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
