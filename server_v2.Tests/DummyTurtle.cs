using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

using System.Net.WebSockets;
using System.Security.Principal;
using System.Text.Json;
using MoonSharp.Interpreter;


namespace server_v2.Tests
{
    public class DummyTurtle
    {
        private readonly WebSocket _ws;
        private readonly CancellationTokenSource _cts = new CancellationTokenSource();
        private static System.Reflection.Assembly assembly = typeof(DummyTurtle).Assembly;
        private static string base_path = typeof(DummyTurtle).Namespace;

        private readonly ScriptWrapper _luaEnv;

        public DummyTurtle(WebSocket ws, ScriptWrapper luaEnv)
        {
            this._ws = ws;
            this._luaEnv = luaEnv;
        }

        public async Task Connect(string computerKey=null)
        {
            //Also run/import the "DummyTurtle" lua env setup:
            var initLua = GetEmbeddedLuaFile("DummyTurtleScript");
            _luaEnv.ExecLua(initLua);
            
            await SendAsync(new { @type = "connecting", computer_db_key = computerKey });
        }

        private async Task SendAsync(string data) => await _ws.SendAsync(Encoding.UTF8.GetBytes(data), WebSocketMessageType.Text, true, _cts.Token);
        public async Task SendAsync<T>(T data) => await SendAsync(System.Text.Json.JsonSerializer.Serialize(data));


        public async Task ReceiveAsync(TimeSpan? timeout = null)
        {
            timeout ??= TimeSpan.FromMilliseconds(2500);
            //always have/use a CTS such that bad server code doesn't lockup the unit tests:
            _cts.CancelAfter(timeout.Value);
            //FIXME: this should actually take/use a time-delay CancellationToken
            var buffer = new ArraySegment<byte>(new byte[2048]);
            do
            {
                string message;
                await using (var ms = new System.IO.MemoryStream())
                {
                    WebSocketReceiveResult res;
                    do
                    {
                        res = await _ws.ReceiveAsync(buffer, _cts.Token);
                        ms.Write(buffer.Array!, buffer.Offset, res.Count);
                    } while (!res.EndOfMessage);
                    if (res.MessageType == WebSocketMessageType.Close)
                    {
                        break;
                    }

                    ms.Seek(0, System.IO.SeekOrigin.Begin);
                    using (var reader = new System.IO.StreamReader(ms, Encoding.UTF8))
                    {
                        message = await reader.ReadToEndAsync();
                    }
                }
                using var msg = System.Text.Json.JsonDocument.Parse(message, new System.Text.Json.JsonDocumentOptions{
                    AllowTrailingCommas = true,
                    CommentHandling = System.Text.Json.JsonCommentHandling.Skip
                });
                System.Diagnostics.Trace.WriteLine($"WS_Receive:{message}");

                if (msg.RootElement.TryGetProperty("type", out var _m_type) &&
                    _m_type.ValueKind == JsonValueKind.String)
                {
                    if (_m_type.GetString() == "eval")
                    {
                        var cmd = Newtonsoft.Json.JsonConvert.DeserializeObject<EvalCommand>(message);
                        //NB: probably a whole pile more prep (getfenv()? setfenv()?) to mimic swarm.main?
                        // EG: we should probably do in-lua same as the je-encode to lua-string to get same-for-same...
                        var res = _luaEnv.ExecLua(cmd.function);
                        var res_str = MoonSharp.Interpreter.Serialization.Json.JsonTableConverter.TableToJson(res.Table);
                        var res_jobj = System.Text.Json.JsonDocument.Parse(res_str);
                        var res_obj = new { 
                            nonce = cmd.nonce, //reply() shape
                            data = new
                            {
                                //LuaCommandModel() shape:
                                ok = true,
                                res = res_jobj
                            }
                        };
                        await SendAsync(res_obj);
                        continue;
                    }
                }
                
                
                throw new NotImplementedException($"TODO: broker message to dispatch.");
            } while (true);
        }

        public class EvalCommand
        {
            public string @type;
            public string function;
            public string nonce;
        }
        
        protected string GetEmbeddedLuaFile(string resName)
        {
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
