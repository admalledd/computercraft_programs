using System;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Linq;
using System.Text;
using System.Threading;
using Microsoft.Extensions.DependencyInjection;

namespace server_v2.Turtle
{
    public abstract class LuaCommand
    {
        
        private static System.Reflection.Assembly assembly = typeof(LuaCommand).Assembly;
        private static string base_path = typeof(LuaCommand).Namespace;

        private Hubs.RawWSHub wsHub;
        protected TurtleBrain turtleBrain;

        //NB: these cross thread pool boundaries potentially (added via UI broker, retreived on websocket manager), and longer-lived, so
        //      try to use the ServiceProvider instead of asking in constructor for EF Context etc things.
        public LuaCommand(Hubs.RawWSHub _wsHub, TurtleBrain _turtleBrain)
        {
            wsHub = _wsHub;
            turtleBrain = _turtleBrain;
        }

        // if J_data == null || j_data_success == false, means we probably didnt get any actual data back... :)
        //NB: this is wrapped alike output of the pcall() (with "ok","res","error" prop-keys)
        //j_data (if above checks out) should have the "res" of your pcall()
        //"{"ok":true,"res":{"pos":{"y":79,"x":120,"z":88}}}"
        public abstract Task Receive(System.Text.Json.JsonElement j_data, bool j_data_success, IServiceProvider sp);
        public static Models.LuaCommandModel<T> JEToObject<T>(System.Text.Json.JsonElement element){
            //https://stackoverflow.com/a/59047063 silly unable to ".ToObject()" a JsonElement... bleh.
            var bufferWriter = new System.Buffers.ArrayBufferWriter<byte>();
            using(var writer = new System.Text.Json.Utf8JsonWriter(bufferWriter)){
                element.WriteTo(writer);
            };
            return System.Text.Json.JsonSerializer.Deserialize<Models.LuaCommandModel<T>>(bufferWriter.WrittenSpan);
        }

        public abstract Task Enqueue(IServiceProvider sp, params object[] args); //?? meh, future me problem.

        private static System.Security.Cryptography.RNGCryptoServiceProvider rng = new System.Security.Cryptography.RNGCryptoServiceProvider();
        private static string GenerateNonce()
        {
            //base64 encodes via four chars per three bytes
            // (++pading)
            // nonce we want human-readable short because debugging... so ~8 bytes encodes via RNG 255 nonces in flight
            //TODO: smart play would be to also check the turtleBrain's current InFlightCommands.Keys, but thread unsafe says meh
            // reality is that (in theory) we should really try to never have more than "none, one, few(!!)" in flight commands.
            byte[] tokenData = new byte[8];
            rng.GetBytes(tokenData);
            return Convert.ToBase64String(tokenData);

        }
        protected virtual async Task Enqueue(string cmdLua)
        {
            //{"type":"eval","nonce":"12345678","function":"return 1+1"}
            var cmd_obj = new {type="eval", function=cmdLua, nonce=GenerateNonce()};
            var cmd_str = System.Text.Json.JsonSerializer.Serialize(cmd_obj);

            //find our attached socket for this brain hopefully:
            await wsHub.SendToTurtleAsync(turtleBrain, cmd_str);
            turtleBrain.InFlightCommands[cmd_obj.nonce] = this;
        }

        public static async Task Enqueue<TLuaCommand>(IServiceProvider serviceProvider, TurtleBrain _tbrain, params object[] args)
            where TLuaCommand : LuaCommand
        {
            //NB: consider refactoring this to not use Activator.CreateInstance(), but I want my arguments!
            var cmd = ActivatorUtilities.CreateInstance<TLuaCommand>(serviceProvider, _tbrain);
            await cmd.Enqueue(serviceProvider, args);
        }

        // pass in a `nameof(this_class)` and it should return the friendly bound LUA file for that one.
        protected string GetCommandString(string resName)
        {
            //NB: eventually probably we might have multiple Lua files for one command? Nahhh never...
            using(var stream = assembly.GetManifestResourceStream($"{base_path}.{resName}.lua"))
            {
                using(var reader = new System.IO.StreamReader(stream))
                {
                    return reader.ReadToEnd();
                }
            }
        }
    }
}