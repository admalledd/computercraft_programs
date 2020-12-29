using System;
using System.Collections.Generic;
using System.Collections.Concurrent;


namespace server_v2.Turtle
{
    public class TurtleBrain
    {
        public string TurtleDBKey {get;set;}

        public ConcurrentDictionary<string, LuaCommand> InFlightCommands = new ConcurrentDictionary<string, LuaCommand>();
    }
}
