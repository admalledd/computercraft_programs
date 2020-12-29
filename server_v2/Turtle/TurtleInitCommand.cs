using System;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Linq;
using System.Text;
using System.Threading;
using server_v2.Hubs;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;


namespace server_v2.Turtle
{
    public class TurtleInitCommand : LuaCommand
    {
        private ILogger<TurtleInitCommand> logger;
        private Microsoft.AspNetCore.SignalR.IHubContext<ChatHub, Hubs.Clients.IChatClient> chatHub;

        public TurtleInitCommand(
            Microsoft.AspNetCore.SignalR.IHubContext<ChatHub, Hubs.Clients.IChatClient> _chatHub,
            ILogger<TurtleInitCommand> _logger,
            RawWSHub _wsHub, TurtleBrain _turtleBrain) : base(_wsHub, _turtleBrain)
        {
            logger = _logger;
            this.chatHub = _chatHub;
        }

        public override async Task Enqueue(IServiceProvider sp, params object[] args)
        {
            var cmd_txt = this.GetCommandString(nameof(TurtleInitCommand));
            await Enqueue(cmd_txt);
        }

        public override async Task Receive(JsonElement j_data, bool j_data_success, IServiceProvider sp)
        {
            if (false == j_data_success){
                // bleh
                await Task.CompletedTask;
            }
            var data = LuaCommand.JEToObject<Models.TurtleInitModel>(j_data);
            

            if (data.ok && data.res?.pos != null){
                var pos = data.res.pos; //unbox a bit
                //TODO: find/update our DB-self, if we also lacking a TurtleKey, (eg we are "new" somehow) then extract that and prep a "set-setting" cmd
                var msg = $"received info all the way back to the desired cmd! posInfo = " +
                    $"({data.res.pos?.x},{data.res.pos?.y},{data.res.pos?.z},{data.res.pos?.dir})";
                logger.LogInformation(msg);
                await chatHub.Clients.All.ReceiveMessage(new Models.ChatMessage{
                    User = $"t:{turtleBrain.TurtleDBKey}",
                    Message = msg
                });

                //we "know" from the raw websocket init that the DB entity *must* exist already, so update the pos we have in DB:
                var context = sp.GetRequiredService<Entities.CCServerContext>();
                var entity_turtle = context.Turtles.Single(t => t.TurtleKey == turtleBrain.TurtleDBKey);
                entity_turtle.Loc_X = data.res.pos?.x ?? 0;
                entity_turtle.Loc_Y = data.res.pos?.y ?? 0;
                entity_turtle.Loc_Z = data.res.pos?.z ?? 0;
                await context.SaveChangesAsync();
                //entity_turtle.Direction = data.res.pos?.dir ?? 0; //we don't care about saving face into DB though.
                if (data.res.computer_db_key == null){
                    await LuaCommand.Enqueue<TurtleSetSettingCommand>(sp, turtleBrain, "computer_db_key", entity_turtle.TurtleKey);
                }
            }
            else{
                logger.LogWarning($"received command failed with error:{data.error}");
            }
            await Task.CompletedTask;
        }
    }
}