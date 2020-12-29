using System.Threading.Tasks;

namespace server_v2.Hubs.Clients
{
    //ChatHub/ChatClient is used more for diagnostic/system log messages from the server
    // actual event hub for further will be elsewhere.
    public interface IChatClient
    {
        Task ReceiveMessage(Models.ChatMessage message);
    }
}