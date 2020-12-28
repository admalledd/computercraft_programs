using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;


namespace server_v2.Entities
{
    public class World
    {
        [Key]
        public long WorldKey {get;set;}
        public string WorldId {get;set;}
        public string WorldName {get;set;}

        public IEnumerable<Block> Blocks {get;set;}
    }
}