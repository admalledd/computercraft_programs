using System;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Linq;
using System.Net.WebSockets;
using System.Text;
using System.Threading;


namespace server_v2.WebSockets
{
    public class WebSocketConnectionManager
    {
        private ConcurrentDictionary<string, WebSocket> _sockets = new ConcurrentDictionary<string, WebSocket>();
        public WebSocket GetSocketById(string id)
        {
            if (_sockets.TryGetValue(id, out var ws)){
                return ws;
            }
            else{
                throw new KeyNotFoundException($"Socket by ID '{id}' not found");
            }
        }
        public bool TryGetSocketById(string id, out WebSocket socket)
        {
            return _sockets.TryGetValue(id, out socket);
        }

        public string GetId(WebSocket socket)
        {
            return _sockets.First(p => p.Value == socket).Key;
        }

        public string AddSocket(WebSocket socket)
        {
            var id = CreateConnectionId();
            _sockets.TryAdd(id, socket);
            return id;
        }

        public async Task RemoveSocket(string id, string reason=null)
        {

            WebSocket socket;
            if (_sockets.TryRemove(id, out socket))
            {
                await socket.CloseAsync(closeStatus: WebSocketCloseStatus.NormalClosure,
                                statusDescription: reason ?? "Closed by the WebSocketConnectionManager",
                                cancellationToken: CancellationToken.None);
            }
            else {
                // TODO: what if no socket?
            }
        }

        public async Task<IEnumerable<(WebSocket Socket, string id)>> GetAll()
        {
            return await Task.FromResult(_sockets.Select(kv => (Socket: kv.Value, id: kv.Key)));
        }

        private static string CreateConnectionId()
        {
            return Guid.NewGuid().ToString();
        }


    }
}