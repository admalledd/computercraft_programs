using System;
using System.Collections.Generic;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace server_v2.Tests
{
    public class DummyTurtle
    {
        WebSocket ws;

        public DummyTurtle(WebSocket _ws)
        {
            ws = _ws;
            
        }

        public async Task Connect(string computerKey=null)
        {
            await SendAsync(new { @type = "connecting", computer_db_key = computerKey });
        }

        async Task SendAsync(string data) => await ws.SendAsync(Encoding.UTF8.GetBytes(data), WebSocketMessageType.Text, true, CancellationToken.None);
        async Task SendAsync<T>(T data) => await SendAsync(System.Text.Json.JsonSerializer.Serialize(data));

        public async Task ReceiveAsync()
        {
            var buffer = new ArraySegment<byte>(new byte[2048]);
            do
            {
                WebSocketReceiveResult res;
                string message;
                using (var ms = new System.IO.MemoryStream())
                {
                    do
                    {
                        res = await ws.ReceiveAsync(buffer, CancellationToken.None);
                        ms.Write(buffer.Array, buffer.Offset, res.Count);
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

                System.Diagnostics.Trace.WriteLine($"WS_Receive:{message}");
                throw new NotImplementedException($"TODO: broker message to dispatch.");
            } while (true);
        }
    }
}
