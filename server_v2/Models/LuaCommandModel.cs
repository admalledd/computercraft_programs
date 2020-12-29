using System.Text.Json;

namespace server_v2.Models
{
    public class LuaCommandModel<TResData>
    {
        //"{"ok":true,"res":{"pos":{"y":79,"x":120,"z":88}}}"
        public bool ok {get;set;}
        public TResData res {get;set;}
        public string error {get;set;}
    }
}