using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.AspNetCore.TestHost;
using System.Threading;
using System;


using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore;
using System.Threading.Tasks;

namespace server_v2.Tests
{
    [TestClass]
    public class ConnectionTests
    {
        [TestMethod]
        public async Task EmptyConnectionTest()
        {
            using var ds = new DummyServer();

            var t = await ds.NewDummyTurtle();
            await t.Connect();
            await t.ReceiveAsync();
            //await Task.Delay(20000);
        }
    }
}
