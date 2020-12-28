using System;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Linq;
using System.Net.WebSockets;
using System.Text;
using System.Threading;

using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System.Reflection;

namespace server_v2.WebSockets
{
    public class WebSocketManagerMiddleware
    {
        private readonly RequestDelegate _next;
        private WebSocketHandler _webSocketHandler { get; set; }

        public WebSocketManagerMiddleware(RequestDelegate next, WebSocketHandler webSocketHandler)
        {
            _next = next;
            _webSocketHandler = webSocketHandler;
        }

        public async Task Invoke(HttpContext context)
        {
            if(!context.WebSockets.IsWebSocketRequest)
                return;

            var socket = await context.WebSockets.AcceptWebSocketAsync();
            await _webSocketHandler.OnConnected(socket);

            await Receive(socket, async(result, buffer) =>
            {
                if(result.MessageType == WebSocketMessageType.Text)
                {
                    await _webSocketHandler.ReceiveAsync(socket, result, buffer);
                    return;
                }

                else if(result.MessageType == WebSocketMessageType.Close)
                {
                    await _webSocketHandler.OnDisconnected(socket);
                    return;
                }

            });
        }

        private async Task Receive(WebSocket socket, Action<WebSocketReceiveResult, byte[]> handleMessage)
        {
            var buffer = new byte[1024 * 4];

            while(socket.State == WebSocketState.Open)
            {
                var result = await socket.ReceiveAsync(buffer: new ArraySegment<byte>(buffer),
                                                        cancellationToken: CancellationToken.None);

                handleMessage(result, buffer);
            }
        }
    }
    public static class WebSocketMiddlewareExtentions
    {
        public static IApplicationBuilder MapWebSocketManager(
            this IApplicationBuilder app, PathString path, WebSocketHandler handler)
        {
            return app.Map(path, (_app) => _app.UseMiddleware<WebSocketManagerMiddleware>(handler));
        }
        public static IApplicationBuilder MapWebSocketManager<WebSocketHandler>(
            this IApplicationBuilder app, PathString path)
        {
            return app.Map(path, (_app) => _app.UseMiddleware<WebSocketManagerMiddleware>(_app.ApplicationServices.GetService<WebSocketHandler>()));
        }

        public static IServiceCollection AddWebSocketManager(this IServiceCollection services)
        {
            services.AddTransient<WebSocketConnectionManager>();
            var logger = services.BuildServiceProvider().GetService<ILogger<WebSocketManagerMiddleware>>();
            //Find all valid handlers via reflection based on exec assembly instead of more-proper "wire up" methodology. Meh. Lazy
            var seenTypes = new Dictionary<Type,bool>();
            void check_type(Type t){
                if (seenTypes.ContainsKey(t)){
                    return;
                }
                seenTypes[t] = true;
                if (t.GetTypeInfo().BaseType == typeof(WebSocketHandler)){
                    logger.LogInformation("adding type: {FullName}",t.FullName);
                    services.AddSingleton(t);
                }
            }
            foreach (var t in Assembly.GetEntryAssembly().ExportedTypes)
            {
                check_type(t);
            }
            //If we are the exe itself, does this even exist? meh
            foreach (var t in Assembly.GetCallingAssembly()?.ExportedTypes)
            {
                check_type(t);
            }
            return services;
        }
    }
}