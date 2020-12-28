using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace server_v2.Entities
{
    public class Block 
    {

        [Key]
        public long BlockKey {get;set;}
        [ForeignKey(nameof(World))]
        public long WorldKey {get;set;}
        public World World {get;set;}
        public long Loc_X {get;set;}
        public long Loc_Y {get;set;}
        public long Loc_Z {get;set;}

        public string BlockId {get;set;}
        //TODO: block metadata stuffs?
        //public int? Damage {get;set;}
    }
}