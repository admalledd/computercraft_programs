using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Logging;
using System.IO;

namespace server_v2.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class GetFileController : ControllerBase
    {
        private readonly Microsoft.AspNetCore.Hosting.IWebHostEnvironment hostEnv;
        public GetFileController(Microsoft.AspNetCore.Hosting.IWebHostEnvironment _hostEnv)
        {
            hostEnv = _hostEnv;
        }

        [HttpGet("GetFile")]
        public FileResult GetFile(string fname)
        {
            var root_path = Path.Combine(hostEnv.ContentRootPath, "..", "cc_code");
            var file_path = Path.Combine(root_path, fname);
            var file_name = Path.GetFileName(file_path);
            return PhysicalFile(file_path, "text/plain", file_name);
        }

        [HttpGet("GetBootstrapFile")]
        public FileResult GetBootstrapFile()
        {
            return GetFile("swarm/bootstrap.lua");
        }
    }
}
