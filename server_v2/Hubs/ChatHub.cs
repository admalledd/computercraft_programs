using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;

namespace server_v2.Hubs
{
    public class ChatHub : Hub<Clients.IChatClient>
    {
        // public async Task SendMessage(string user, string message)
        // {
        //     this.Clients.All.ReceiveMessage

        //     await Clients.All.SendAsync("ReceiveMessage", user, message);
        // }
    }
}