using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace server_v2.Tests
{
    public class DummyServer : IAsyncDisposable, IDisposable
    {
        public TestServer TestServer;
        public Entities.CCServerContext TestContext;
        public IServiceProvider Services => _serviceScope?.ServiceProvider;
        private readonly IServiceScope _serviceScope;

        public DummyServer()
        {
            var builder = WebHost.CreateDefaultBuilder()
                .UseStartup<DummyStartup>() //TODO: unit-test direct subclass/injector of <Startup_TestBase>
                .UseEnvironment("Development");

            TestServer = new TestServer(builder);
            _serviceScope = TestServer.Services.CreateScope();
            TestContext = Services.GetRequiredService<Entities.CCServerContext>();
        }

        public async Task<DummyTurtle> NewDummyTurtle(string turtleKey=null)
        {

            var tws = TestServer.CreateWebSocketClient();
            var ws = await tws.ConnectAsync(new UriBuilder(TestServer.BaseAddress)
            {
                Scheme = "ws",
                Path = "ws"
            }.Uri, CancellationToken.None);
            var t = ActivatorUtilities.CreateInstance<DummyTurtle>(Services, ws);
            return await Task.FromResult(t);
        }


        #region IDisposable

        private bool _disposed = false;
        protected void CheckDisposed()
        {
            if (_disposed)
            {
                throw new ObjectDisposedException(this.GetType().FullName);
            }
        }
        async ValueTask IAsyncDisposable.DisposeAsync()
        {
            if (TestContext != null)
            {
                await TestContext.DisposeAsync();
                TestContext = null;
            }
            if (TestServer != null)
            {
                TestServer.Dispose();
                TestServer = null;
            }
            this.Dispose(false);
            GC.SuppressFinalize(this);
        }
        void IDisposable.Dispose()
        {
            this.Dispose(true);
            GC.SuppressFinalize(this);
        }
        protected virtual void Dispose(bool disposing)
        {
            if (_disposed) return;
            if (disposing)
            {
                TestContext?.Dispose();
                TestContext = null;
                TestServer?.Dispose();
                TestServer = null;
            }
            _disposed = true;
        }

        #endregion
    }
}
