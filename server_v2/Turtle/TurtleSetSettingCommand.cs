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
    public class TurtleSetSettingCommand : LuaCommand
    {
        
        private ILogger<TurtleSetSettingCommand> logger;

        public TurtleSetSettingCommand(Hubs.RawWSHub _wsHub, ILogger<TurtleSetSettingCommand> _logger, TurtleBrain _turtleBrain) : base(_wsHub, _turtleBrain)
        {
            logger = _logger;
            
        }
        public override async Task Enqueue(IServiceProvider sp, params object[] args)
        {
            //unpack into arg[0]==key and arg[1] == val
            // wow I am exceedingly lazy so fix more of this later... for now we only really need to set db_key anywho.
            var key = (string)args[0];
            var value = (string)args[1];
            var cmd_txt = $@"
            settings = require('settings')
            settings['{key}']='{value}';
            local function readSettings()
                local f = fs.open('/settings.json','r')
                local txt = f.readAll()
                f.close()
                return txt
            end
            return readSettings()"; //why not just do a read back eh?
            await Enqueue(cmd_txt);
        }

        public override async Task Receive(JsonElement j_data, bool j_data_success, IServiceProvider sp)
        {
            if (false == j_data_success){
                // bleh
                await Task.CompletedTask;
            }

            var data = LuaCommand.JEToObject<dynamic>(j_data);
            

            if (data.ok){
                //TODO: find/update our DB-self, if we also lacking a TurtleKey, (eg we are "new" somehow) then extract that and prep a "set-setting" cmd
                var msg = $"settings updated!";
                logger.LogInformation(msg);
            }
            else{
                logger.LogWarning($"received command failed with error:{data.error}");
            }
            await Task.CompletedTask;
        }

    }
}
