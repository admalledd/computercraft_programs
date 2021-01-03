using System;
using System.Collections.Generic;


namespace server_v2.Models
{
    public class TurtleBlocksInspectModel
    {
        /*
            local pos = {{x=x,y=y,z=z,dir=dir}}
            return {{up=b_up,down=b_down,forward=b_fwd,pos=pos}}
        */
        public TurtlePosModel pos {get;set;}
        public LuaCommandModel<TurtleBlockModel> up {get;set;}
        public LuaCommandModel<TurtleBlockModel> down {get;set;}
        public LuaCommandModel<TurtleBlockModel> forward {get;set;}

    }
    public class TurtleBlockModel
    {
        //TODO: ??? what is actual reasonable shape of this? we at least want the "block-type" thing right?
        /*
            {
                "state": {} ??,
                "name: "minecraft:stone"
                "tags": {Dictionary<string,object>}
                //NB: where is other metadata? (or is that a different thing? hrm)
            }
        */
        public Dictionary<string,object> state {get;set;}
        public string name {get;set;}
        public Dictionary<string,object> tags {get;set;}
    }
}
