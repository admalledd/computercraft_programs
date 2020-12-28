using Microsoft.EntityFrameworkCore.Migrations;

namespace server_v2.Migrations
{
    public partial class InitialCreate : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Turtles",
                columns: table => new
                {
                    TurtleKey = table.Column<string>(type: "TEXT", nullable: false),
                    TurtleCurrentWSGuid = table.Column<string>(type: "TEXT", nullable: true),
                    Loc_X = table.Column<long>(type: "INTEGER", nullable: false),
                    Loc_Y = table.Column<long>(type: "INTEGER", nullable: false),
                    Loc_Z = table.Column<long>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Turtles", x => x.TurtleKey);
                });

            migrationBuilder.CreateTable(
                name: "World",
                columns: table => new
                {
                    WorldKey = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    WorldId = table.Column<string>(type: "TEXT", nullable: true),
                    WorldName = table.Column<string>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_World", x => x.WorldKey);
                });

            migrationBuilder.CreateTable(
                name: "Blocks",
                columns: table => new
                {
                    BlockKey = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    WorldKey = table.Column<long>(type: "INTEGER", nullable: false),
                    Loc_X = table.Column<long>(type: "INTEGER", nullable: false),
                    Loc_Y = table.Column<long>(type: "INTEGER", nullable: false),
                    Loc_Z = table.Column<long>(type: "INTEGER", nullable: false),
                    BlockId = table.Column<string>(type: "TEXT", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Blocks", x => x.BlockKey);
                    table.ForeignKey(
                        name: "FK_Blocks_World_WorldKey",
                        column: x => x.WorldKey,
                        principalTable: "World",
                        principalColumn: "WorldKey",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Blocks_WorldKey",
                table: "Blocks",
                column: "WorldKey");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Blocks");

            migrationBuilder.DropTable(
                name: "Turtles");

            migrationBuilder.DropTable(
                name: "World");
        }
    }
}
