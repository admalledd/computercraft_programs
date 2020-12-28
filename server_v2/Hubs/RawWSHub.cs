using System;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Linq;
using System.Net.WebSockets;
using System.Text;
using System.Threading;

using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Logging;

namespace server_v2.Hubs
{
    public class RawWSHub : WebSockets.WebSocketHandler
    {
        private IHubContext<ChatHub, Clients.IChatClient> chatHub;
        public RawWSHub(WebSockets.WebSocketConnectionManager webSocketConnectionManager, IHubContext<ChatHub, Clients.IChatClient> _chatHub, ILogger<RawWSHub> _logger) : base(webSocketConnectionManager, _logger)
        {
            chatHub = _chatHub;
        }

        public override async Task<string> OnConnected(WebSocket socket)
        {
            var socketId = await base.OnConnected(socket);
            await chatHub.Clients.All.ReceiveMessage(new Models.ChatMessage{User=$"ws:{socketId}", Message="OnConnected"});
            logger.LogInformation($"ws:{socketId} OnConnected");
            return socketId;
        }

        public override async Task ReceiveAsync(WebSocket socket, WebSocketReceiveResult result, byte[] buffer)
        {
            var socketId = WebSocketConnectionManager.GetId(socket);
            var message = $"{socketId} said: {Encoding.UTF8.GetString(buffer, 0, result.Count)}";

            logger.LogInformation(message);

            await chatHub.Clients.All.ReceiveMessage(new Models.ChatMessage{
                User=$"ws:{socketId}",
                Message=message});
        }
    }
}