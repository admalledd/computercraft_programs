using Microsoft.EntityFrameworkCore;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace server_v2.Entities
{
    public abstract class History
    {
        [Key]
        public long HistoryKey {get;set;}
        //NB: as part of "magic" this would need to mirror PK of parent
        //NB: intentionally NOT a FK, to support keeping DELETE history.
        public long ParentKey {get;set;}
        public DateTime HistoryDateTime {get;set;}
        //NB: "Source" is/should be context sensative but same for entire history table. Can be NULL if useless
        public int? HistorySource {get;set;}

        public EHistoryType HistoryType {get;set;}
        public enum EHistoryType : ushort
        {
            INSERT = 0,
            UPDATE = 1,
            DELETE = 2
        }
    }
}