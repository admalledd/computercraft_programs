using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace server_v2.Entities
{
    public class CCServerContext : DbContext
    {
        public CCServerContext(DbContextOptions<CCServerContext> options) : base(options)
        {

            //TODO: somehow get the Turtle/Blocks to have a "history/audit" table auto-magic, but based on reliable triggers vs impied provider magic
            //      provider magic is unreliable (and also, "what if direct query for optimizations/mass updates?"), so pure-DB method of building 
            //      the historic records is desired. However some automagic EFMigration supported method of *building* that pure-DB method, as well
            //      as building the read-only historical tables.
        }

        public DbSet<Turtle> Turtles {get;set;}
        public DbSet<Block> Blocks {get;set;}
        public DbSet<World> World {get;set;}
    }
}