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
using Microsoft.Extensions.DependencyInjection;

namespace server_v2.Hubs
{
    public class RawWSHub : WebSockets.WebSocketHandler
    {
        private IHubContext<ChatHub, Clients.IChatClient> chatHub;

        private IServiceProvider serviceProvider;

        private static ConcurrentDictionary<string, Turtle.TurtleBrain> connectionMap = new ConcurrentDictionary<string, Turtle.TurtleBrain>();
        private static ConcurrentDictionary<Turtle.TurtleBrain, string> reverseConnectionMap = new ConcurrentDictionary<Turtle.TurtleBrain, string>();
        private static ConcurrentDictionary<string, Turtle.TurtleBrain> turtleIdMap = new ConcurrentDictionary<string, Turtle.TurtleBrain>();


        public RawWSHub(
            WebSockets.WebSocketConnectionManager webSocketConnectionManager,
            IHubContext<ChatHub, Clients.IChatClient> _chatHub,
            IServiceProvider _serviceProvider,
            ILogger<RawWSHub> _logger) : base(webSocketConnectionManager, _logger)
        {
            chatHub = _chatHub;
            serviceProvider = _serviceProvider;
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
            var raw_message = Encoding.UTF8.GetString(buffer, 0, result.Count);

            logger.LogInformation($"ws:{socketId} said: {raw_message}");

            //raw_message should always be JSON object and have a "nonce" field (excluding first init cmd)
            // From these two we can build a two-layer mapping to get backing turtle:
            // static ConcurrentDictionary<WebSocket(GUID), TurtleBrain>()
            // TurtleBrain.InFlight<sting(nonce),LuaCommand>()
            using var msg = System.Text.Json.JsonDocument.Parse(raw_message, new System.Text.Json.JsonDocumentOptions{
                AllowTrailingCommas = true,
                CommentHandling = System.Text.Json.JsonCommentHandling.Skip
            });

            using var serviceScope = serviceProvider.CreateScope();
            var context = serviceScope.ServiceProvider.GetRequiredService<Entities.CCServerContext>();

            //TODO: add logger.LogDebut() / logger.LogTrace() for these
            if (!connectionMap.TryGetValue(socketId, out var turtleBrain)){
                // we don't know this turtle yet...
                // check if message is "connecting", this is all a bit hard coded because of "who is on first problems"
                //ws.send(je({type='connect',computer_db_key=settings.computer_db_key}))
                if (msg.RootElement.TryGetProperty("type", out var _msg_type)){
                    if (_msg_type.GetString() == "connecting"){
                        //TODO: remove prior stale turtle brain mappings
                        if (msg.RootElement.TryGetProperty("computer_db_key", out var _msg_t_id)){
                            // in theory, existing turtle.
                            var turtleKey = _msg_t_id.GetString();
                            if (turtleIdMap.TryGetValue(turtleKey, out var tbrain)){
                                connectionMap[socketId] = tbrain;
                                reverseConnectionMap[turtleBrain] = socketId;
                                turtleBrain = tbrain;
                            }
                            else{
                                //stale, pull from DB again:
                                var tEntity = context.Turtles.FirstOrDefault(t => t.TurtleKey == turtleKey);
                                if (tEntity == null){
                                    // LIES we DID NOT HAVE YOU, WHO ARE YOU? IMPOSTER!
                                    // Welcome aboard anyways, we don't vote turtles out here :)
                                    turtleBrain = new Turtle.TurtleBrain();
                                    tEntity = new Entities.Turtle(){
                                        TurtleKey = Guid.NewGuid().ToString(),
                                        TurtleCurrentWSGuid = socketId
                                    };
                                    context.Turtles.Add(tEntity);
                                    await context.SaveChangesAsync();
                                    turtleBrain.TurtleDBKey = tEntity.TurtleKey;
                                    connectionMap[socketId] = turtleBrain;
                                    reverseConnectionMap[turtleBrain] = socketId;
                                    turtleIdMap[turtleBrain.TurtleDBKey] = turtleBrain;
                                }
                                else{
                                    turtleBrain = new Turtle.TurtleBrain();
                                    turtleBrain.TurtleDBKey = tEntity.TurtleKey;
                                    connectionMap[socketId] = turtleBrain;
                                    reverseConnectionMap[turtleBrain] = socketId;
                                    turtleIdMap[turtleBrain.TurtleDBKey] = turtleBrain;
                                }
                            }
                        }
                        else{
                            //new turtle
                            turtleBrain = new Turtle.TurtleBrain();
                            var tEntity = new Entities.Turtle(){
                                TurtleKey = Guid.NewGuid().ToString(),
                                TurtleCurrentWSGuid = socketId
                            };
                            context.Turtles.Add(tEntity);
                            await context.SaveChangesAsync();
                            turtleBrain.TurtleDBKey = tEntity.TurtleKey;
                            connectionMap[socketId] = turtleBrain;
                            reverseConnectionMap[turtleBrain] = socketId;
                            turtleIdMap[turtleBrain.TurtleDBKey] = turtleBrain;
                        }
                    }
                    else {
                        //TODO: wat?
                        logger.LogWarning($"Unknown turtle socketId: {socketId}");
                        return;
                    }
                }
                else {
                    //TODO: wat?
                    logger.LogWarning($"Unknown turtle socketId: {socketId}");
                    return;
                }
            }
            //sanity check the above, cause yikes if not:
            if (turtleBrain == null){
                logger.LogError($"turtleBrain on ws:Receive shouldn't ever get this far? wsId:{socketId}");
                return;
            }
            //Basically everything should be return-brokered by nonce's, the only thing that isn't/cant is the inital "connecting"...
            if (msg.RootElement.TryGetProperty("nonce", out var j_nonce)){
                //got a nonce, check for existing inflight cmd
                var nonce = j_nonce.GetString();
                if (turtleBrain.InFlightCommands.TryRemove(nonce, out var command)){
                    //TODO:: return msg to command
                    var j_get_success = msg.RootElement.TryGetProperty("data", out var j_data);
                    await command.Receive(j_data, j_get_success, serviceScope.ServiceProvider);
                    return;
                }
                else{
                    logger.LogWarning($"turtleBrain for {turtleBrain.TurtleDBKey} lost tracking of in-flight nonce:{nonce}");
                    return;
                }
            }
            else{
                if (msg.RootElement.TryGetProperty("type", out var _msg_type)){
                    if (_msg_type.GetString() == "connecting"){
                        //Thus if we are the special "connecting" case, run our post-connect init code over:
                        await Turtle.LuaCommand.Enqueue<Turtle.TurtleInitCommand>(serviceScope.ServiceProvider, turtleBrain);
                        return;
                    }
                }
                logger.LogWarning($"turtleBrain for {turtleBrain.TurtleDBKey} received a message we didn't know how to handle :( ");
                return;
                //invalid command probably? yea, lets go with that.
            }
        }

        public async Task SendToTurtleAsync(Turtle.TurtleBrain turtleBrain, string message)
        {
            //attempt to get/find socket per what we remember of reverseConnectionMap:
            if (!reverseConnectionMap.TryGetValue(turtleBrain, out var socketId))
            {
                logger.LogWarning($"Attempted send a message to turtle {turtleBrain.TurtleDBKey} but no reverseConnection found!");
                return;
            }
            if (!WebSocketConnectionManager.TryGetSocketById(socketId, out var socket))
            {
                logger.LogWarning($"Attempted send a message to turtle {turtleBrain.TurtleDBKey} but connection ws:{socketId} was missing!");
                return;
            }
            //Check for orphaned/broken socket here to log about that instead of silently dropping, note of course this is just best-effort:
            if (socket.State != WebSocketState.Open)
            {
                logger.LogWarning($"Attempted send a message to turtle {turtleBrain.TurtleDBKey} but connection ws:{socketId} is dead!");
                return;
            }
            await this.SendMessageAsync(socket, message);
        }

        public IEnumerable<Turtle.TurtleBrain> GetConnectedBrains()
        {
            return reverseConnectionMap.Keys;
        }
    }
}