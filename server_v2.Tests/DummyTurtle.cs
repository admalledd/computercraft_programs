using System;
using System.Collections.Generic;
using System.Net.WebSockets;
using System.Security.Principal;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace server_v2.Tests
{
    public class DummyTurtle
    {
        private readonly WebSocket _ws;
        private readonly CancellationTokenSource _cts = new CancellationTokenSource();

        public DummyTurtle(WebSocket ws)
        {
            this._ws = ws;
        }

        public async Task Connect(string computerKey=null)
        {
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

                System.Diagnostics.Trace.WriteLine($"WS_Receive:{message}");
                throw new NotImplementedException($"TODO: broker message to dispatch.");
            } while (true);
        }
    }
}
