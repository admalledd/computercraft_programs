using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Logging;

namespace server_v2.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ChatController : ControllerBase
    {
        private readonly IHubContext<Hubs.ChatHub, Hubs.Clients.IChatClient> chatHub;
        private readonly Hubs.RawWSHub wsHub;
        private readonly IServiceProvider serviceProvider;

        public ChatController(IHubContext<Hubs.ChatHub, Hubs.Clients.IChatClient> _chatHub, Hubs.RawWSHub _wsHub, IServiceProvider _serviceProvider)
        {
            chatHub = _chatHub;
            wsHub = _wsHub;
            serviceProvider = _serviceProvider;
        }

        [HttpPost("messages")]
        public async Task Post(Models.ChatMessage message)
        {
            // run some logic...
            await wsHub.SendMessageToAllAsync(message.Message);
            await chatHub.Clients.All.ReceiveMessage(message);
        }

        [HttpPost("helloworld")]
        public async Task HelloWorld(string bleh)
        {
            foreach (var tb in wsHub.GetConnectedBrains())
            {
                await Turtle.LuaCommand.Enqueue<Turtle.TurtleInitCommand>(serviceProvider, tb);
            }
        }
    }
}
