using System;
using System.Collections.Generic;
using System.Text;

namespace server_v2.Tests
{
    public class DummyTurtleState
    {
        public int X;
        public int Y;
        public int Z;
        public string computer_db_key;

        public EFacing dir;
        public enum EFacing
        {
            NORTH,
            EAST,
            SOUTH,
            WEST
        }
    }
}
