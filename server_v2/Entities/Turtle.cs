using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;


namespace server_v2.Entities
{
    public class Turtle 
    {
        [Key]
        public string TurtleKey {get;set;}
        public string TurtleCurrentWSGuid {get;set;}

        public long Loc_X {get;set;}
        public long Loc_Y {get;set;}
        public long Loc_Z {get;set;}
    }
}