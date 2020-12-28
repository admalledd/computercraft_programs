using System.Threading.Tasks;

namespace server_v2.Hubs.Clients
{
    public interface IChatClient
    {
        Task ReceiveMessage(Models.ChatMessage message);
    }
}