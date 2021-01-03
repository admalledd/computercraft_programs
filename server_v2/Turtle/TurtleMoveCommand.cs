using System;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Linq;
using System.Text;
using System.Threading;

namespace server_v2.Turtle
{
    public class TurtleMoveCommand : LuaCommand
    {
        private ILogger<TurtleMoveCommand> logger;

        public TurtleMoveCommand(Hubs.RawWSHub _wsHub, ILogger<TurtleMoveCommand> _logger, TurtleBrain _turtleBrain) : base(_wsHub, _turtleBrain)
        {
            logger = _logger;
            
        }
        public override async Task Enqueue(IServiceProvider sp, params object[] args)
        {
            //unpack into arg[0]==key and arg[1] == val
            
            // move types:
            // forward, back, up, down
            // turn types:
            // left, right

            var moveType = (EMoveType)args[0];
            string moveTxt;
            switch (moveType)
            {
                case EMoveType.Forward:
                    moveTxt = $"turtle.forward()";
                    break;
                case EMoveType.Back:
                    moveTxt = $"turtle.back()";
                    break;
                case EMoveType.Up:
                    moveTxt = $"turtle.up()";
                    break;
                case EMoveType.Down:
                    moveTxt = $"turtle.down()";
                    break;
                case EMoveType.TurnLeft:
                    moveTxt = $"turtle.turnLeft()";
                    break;
                case EMoveType.TurnRight:
                    moveTxt = $"turtle.turnRight()";
                    break;
                case EMoveType.InspectPos:
                default:
                    moveType = EMoveType.InspectPos; //safety
                    moveTxt = $@"(function() return true,nil end)()";
                    break;
            }
            var cmd_txt = $@"
            local inspectPos = require('inspectPos')
            local function move()
                --write out a example full branch of movement to figure out how we want it shapped
                local ok, err = {moveTxt}
                local blocks = inspectPos()
                return {{ok=ok,err=err, blocks=blocks, moveType='{moveType.ToString("G")}'}} --Note, re-incluse moveType for receive decoding help
            end
            return function move()
            ";
            await Enqueue(cmd_txt);
        }

        public enum EMoveType 
        {
            InspectPos, //default because it is safe, basically "do no move, but send back the up/front/down turtle.inspect()"
            Forward, Back,
            Up, Down,
            TurnLeft,
            TurnRight
        }

        public override async Task Receive(JsonElement j_data, bool j_data_success, IServiceProvider sp)
        {
            if (false == j_data_success){
                // bleh
                await Task.CompletedTask;
            }

            var data = LuaCommand.JEToObject<Models.TurtleBlocksInspectModel>(j_data);
            

            if (data.ok){
                //TODO: find/update our DB-self, if we also lacking a TurtleKey, (eg we are "new" somehow) then extract that and prep a "set-setting" cmd
                var pos = data.res.pos;
                var msg = $"we moved! ({pos.x},{pos.y},{pos.z},{pos.dir}) and around us is: "+
                    $"(up='{data.res.up?.res?.name ?? "minecraft:air"}', "+
                    $"forward='{data.res.forward?.res?.name ?? "minecraft:air"}', "+
                    $"down='{data.res.up?.res?.name ?? "minecraft:air"}')";
                logger.LogInformation(msg);
            }
            else{
                logger.LogWarning($"received command failed with error:{data.error}");
            }
            await Task.CompletedTask;
        }
    }
}
