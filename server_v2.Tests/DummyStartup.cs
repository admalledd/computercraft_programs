using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.Common;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace server_v2.Tests
{
    public class DummyStartup : Startup
    {
        private DbConnection contextConnection;

        public DummyStartup(IConfiguration configuration) : base(configuration)
        {
        }

        public override void ConfigureServices(IServiceCollection services)
        {
            base.ConfigureServices(services);
            //With normal startup complete, replace a few things with mockable/testable instead:

            var ctx_descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(DbContextOptions<Entities.CCServerContext>));
            if (ctx_descriptor != null) services.Remove(ctx_descriptor);

            contextConnection = new Microsoft.Data.Sqlite.SqliteConnection("Data Source=:memory:");
            contextConnection.Open();

            services.AddDbContext<Entities.CCServerContext>(options =>
            {
                options.UseSqlite(contextConnection);
            });

            var sp = services.BuildServiceProvider();
            using (var scope = sp.CreateScope())
            {
                var s = scope.ServiceProvider;
                var db = s.GetRequiredService<Entities.CCServerContext>();
                var logger = s.GetRequiredService<ILogger<DummyServer>>();

                try
                {
                    db.Database.EnsureDeleted();
                    db.Database.Migrate();
                    var turtles = db.Turtles.ToList();
                    logger.LogTrace($"built empty test db successfully");
                    //TODO: seed data?
                }
                catch (Exception ex)
                {
                    logger.LogError(ex, $"an error occurred init test db: {ex.Message}");
                    throw;
                }
            }
        }
        public override void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            base.Configure(app, env);
        }
    }
}
