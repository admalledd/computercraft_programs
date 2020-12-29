namespace server_v2.Models
{
    public class TurtleInitModel
    {
        /*
            pos = {x=x,y=y,z=z,dir=dir}
            return {computer_db_key=settings.computer_db_key, pos=pos}
        */
        public string computer_db_key {get;set;}
        public TurtlePosModel pos {get;set;}
    }
    public class TurtlePosModel
    {
        public int? x {get;set;}
        public int? y {get;set;}
        public int? z {get;set;}

        /// NORTH / EAST / SOUTH / WEST
        public string dir {get;set;}
    }
}