using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using MoonSharp.Interpreter;
using MoonSharp.Interpreter.Debugging;

namespace server_v2.Tests
{
    public class ScriptWrapper
    {
        public Script _Script { get; private set; }
        
        internal ScriptWatchDog WatchDog { get; private set; }


        internal ILogger<ScriptWrapper> Logger { get; private set; }
        private long Cycles { get; set; } = 0;
        private System.Diagnostics.Stopwatch Timer { get; set; } = System.Diagnostics.Stopwatch.StartNew();

        private bool _skipCoruFlag = false; //??

        internal Table SharedMetaTable
        {
            get
            {
                var name = "SW_SharedMetaTable";
                var mt = this._Script.Globals.Get(name);
                if (mt == null || mt.Type == DataType.Nil)
                {
                    mt = DynValue.NewTable(this._Script);
                    mt.Table["__index"] = this._Script.Globals;
                    this._Script.Globals[name] = mt;
                }
                return mt.Table;
            }
        }

        internal void SignalHaltExecution()
        {
            Flag_StopExecution = true;
        }

        private bool Flag_StopExecution { get; set; } = false;

        public ScriptWrapper(ILogger<ScriptWrapper> logger, ILogger<ScriptWatchDog> logger_wd) //TODO: more things in default script inject/memory?
        {
            // NB: no JSON etc from M# since CC:TW's JSON is incompatible/different. So we will "import/add" the pure LUA versions later
            this._Script = new Script(CoreModules.Preset_HardSandbox);
            Logger = logger;
            WatchDog = new ScriptWatchDog(logger_wd);
            _Script.Options.DebugPrint = s => logger.LogDebug($"DebugPrint:::{s}");
        }

        public DynValue CallFunc(string luaFuncName, params object[] args)
        {
            var f = _Script.LoadString($"return {luaFuncName}(table.unpack({{...}}))");
            return DoCoru(f.Function, args);
        }

        public DynValue ExecLua(string luaCode)
        {
            try
            {
                var loadLambda = _Script.LoadString(luaCode);
                _skipCoruFlag = true;
                var res = DoCoru(loadLambda.Function);
                
                //lua code could be a func-in-func deal of nesting (common when dyn lua or arg unpacking needed)
                // so check if our return is another function right away and simply do a double call inline
                // Anything more, and something probably went very wrong?
                if (res != null && res.Type == DataType.Function)
                {
                    res = DoCoru(res.Function);
                }
                return res;
            }
            catch (MoonSharp.Interpreter.SyntaxErrorException e)
            {
                Logger.LogCritical($"Syntax error in expected clean lua: {e.Message}::{e.DecoratedMessage}");
                Console.WriteLine(e);
                throw;
            }
            finally
            {
                _skipCoruFlag = false;
            }
        }

        public DynValue DoCoru(Closure func, params object[] args)
        {
            return DoCoru(_Script.CreateCoroutine(DynValue.NewClosure(func)).Coroutine, args);
        }

        public DynValue DoCoru(Coroutine coru, params object[] args)
        {
            coru.AutoYieldCounter = 1; //every instruction
            DynValue res = null;
            WatchDog.FeedWatchDog(); //Every time we begin this loop we assume it is safe to feed, that beats are fine.
            //TODO: CancellationToken support?
            try
            {
                for (
                    //first iteration
                    res = coru.Resume(args);
                    //that it was from our forced/auto-yield
                    res.Type == DataType.YieldRequest && res.YieldRequest.Forced == true;
                    //continuing iterations
                    res = coru.Resume()
                )
                {
                    Cycles += 1;
                    if (WatchDog.DebuggingEnabled && _skipCoruFlag == false)
                    {
                        // set breakpoints here for deep introspection
                        // init the specific SW with a enabled watchdog debugger flag and you can inspect cycle by cycle the funcs.
                        var st = coru.GetStackTrace(0);
                    }
                    
                    if (Flag_StopExecution == true)
                    {
                        //NB: maybe throw/nil instead? hrm
                        return null;
                    }

                    if (Timer.Elapsed > TimeSpan.FromMinutes(30) || Cycles > 200_000)
                    {
                        //TODO: stack trace
                        throw new Exception($"Lua timeout/stuck in loop somewhere probably");
                    }
                }
            }
            catch (Exception ex)
            {
                IEnumerable<MoonSharp.Interpreter.Debugging.WatchItem> st = null;
                if (ex is ScriptRuntimeException sre)
                {
                    // Why can this ever be null dang it?
                    st = sre.CallStack;
                }

                if (st == null || false == st.Any())
                {
                    //For some reason a SRE can have a empty callstack, even though coru has one... 
                    st = coru.GetStackTrace(0);
                }

                var st_path = string.Join(":>>:", st.Reverse().Select(s => s.Name));
                var wex = new Exception($"Lua Interp exception somewhere along the stack of {st_path}", ex);
                Logger.LogWarning("Lua Interp lost its mind:", wex);
                throw wex;
            }
            finally
            {
                Timer.Stop();
            }
            // Actual result of requested stub
            return res;
        }
        
        public class ScriptWatchDog : IDebugger
        {
            internal Script _Script
            {
                get { return DebugService.OwnerScript; }
            }

            protected DebugService DebugService;
            protected readonly ILogger<ScriptWatchDog> Logger;
            private string WasLastCallACLRCall = null;
            public bool DebuggingEnabled = false; // actual flag that enables debugging, else we are only a watchdog
            public string[] ByteCodes;
            public int CurrentIP;
            public int LastIP;

            public long InstructionsExecuted = 0;
            private long _fedAtOpNumber = 0;
            private long _maxOpCount;
            private TimeSpan _timeout;
            private System.Diagnostics.Stopwatch _stopwatch;

            private List<DynamicExpression> m_Dynamics = new List<DynamicExpression>();

            public Dictionary<WatchType, IEnumerable<WatchItem>> Watches =
                new Dictionary<WatchType, IEnumerable<WatchItem>>();

            public ScriptWatchDog(ILogger<ScriptWatchDog> logger, long maxOpCount = 50000, TimeSpan? timeout = null)
            {
                Logger = logger;
                _maxOpCount = maxOpCount;
                _timeout = timeout ?? TimeSpan.FromMinutes(30); //NB: change this way down when not debugging!
                _stopwatch = new Stopwatch();
            }

            public void FeedWatchDog()
            {
                _fedAtOpNumber = InstructionsExecuted;
                _stopwatch.Restart();
            }

            public DebuggerAction GetAction(int ip, SourceRef sourceref)
            {
                CurrentIP = ip;
                InstructionsExecuted += 1;
                if (DebuggingEnabled && CurrentIP != LastIP)
                {
                    var bc = ByteCodes[CurrentIP];
                    if (bc.StartsWith("RET") || WasLastCallACLRCall != null)
                    {
                        string fname = WasLastCallACLRCall ?? Watches[WatchType.CallStack].First().Name;
                        string val = "nil";
                        if (bc.EndsWith("1") || WasLastCallACLRCall != null)
                        {
                            //Only bother special casing "single value returns" for now?
                            val = Watches[WatchType.VStack].First().Value.ToDebugPrintString();
                        }
                        else if (bc.EndsWith("0"))
                        {
                            // no returned values at all
                            val = "nil";
                        }
                        else
                        {
                            Logger.LogDebug($"RET from '{fname}' had unkn RET bytecode of `{bc}`");
                        }

                        var msg = $"RET from '{fname}' val=`{val}`";
                        Logger.LogDebug(msg);
                        WasLastCallACLRCall = null; // reset CLR flag
                        /*
                         * RET n:
                         *   Pops the top n values of the v-stack
                         *   Then pops an X value from the v-stack
                         *   Then pops X values from the v-stack
                         *   Afterwards, it pushes the top n values popped in the first step, pops the top of the x-stack and jumps to that location 
                         */
                    }
                    else if (bc.StartsWith("CALL"))
                    {
                        var argsCount = int.Parse(bc.Split(new char[0], StringSplitOptions.RemoveEmptyEntries)[1]);
                        var dynFn = Watches[WatchType.VStack].Skip(argsCount).First().Value;
                        string fname = null;
                        if (dynFn.Type == DataType.ClrFunction)
                        {
                            fname = dynFn.Callback.Name;
                            WasLastCallACLRCall = fname;
                        }
                        else if (dynFn.Type == DataType.Function)
                        {
                            var fnbc = ByteCodes[dynFn.Function.EntryPointByteCodeLocation];
                            fname = fnbc.Split(new char[0], 5, StringSplitOptions.RemoveEmptyEntries)[3];
                        }
                        else
                        {
                            Logger.LogDebug($"CALL with unkn bytecode of `{bc}`");
                        }

                        var args = Watches[WatchType.VStack].Take(argsCount).Reverse()
                            .Select(s => s.Value.ToDebugPrintString());
                        var msg = $"CALL '{fname}' with args=`{string.Join("`,`", args)}`, stmt=`{ /*TODO: get stack/line number src */ null}`";
                        Logger.LogDebug(msg);
                        /*
                         * CALL
                         *   Calls the function specified on the specified element from the top of the v-stack.
                         *   If the function is a MoonSharp function, it pushes its numeric value onto the v-stack,
                         *     then pushes the current PC onto the x-stack, enters the function closure and jumps to the first bc/instruction of the function
                         *   If the function is a CLR function, it pops the function value from the v-stack,
                         *     then ?.Invokes() the function synchronously and finally pushes the result on the v-stack.
                         */
                    }
                }

                if (LastIP != CurrentIP) //Nit: this is actually how it should be for sub-class injected/real debugger ops (eg "rewind")
                {
                    CurrentIP = LastIP;
                }

                if (InstructionsExecuted - _fedAtOpNumber > _maxOpCount)
                {
                    //TODO: get M# stack traces
                    throw new Exception($"Lua interpreter probably stuck in a loop, aborting execution");
                }

                if (_stopwatch.Elapsed > _timeout)
                {
                    throw new Exception(
                        $"Lua interpreter probably stuck in a loop (or CLR is blocked? or debugging?) aborting execution");
                }
                
                return new DebuggerAction() { Action = DebuggerAction.ActionType.StepIn };
            }
            
            public bool SignalRuntimeException(ScriptRuntimeException ex)
            {
                return false;
            }

            
            public DebuggerCaps GetDebuggerCaps()
            {
                if (DebuggingEnabled)
                {
                    //NB: can't get bytecodes unless we also take source (even if no-op)
                    return DebuggerCaps.CanDebugByteCode | DebuggerCaps.CanDebugSourceCode |
                           DebuggerCaps.HasLineBasedBreakpoints;
                }
                else
                {
                    return 0;
                }
            }

            public void SetDebugService(DebugService debugService)
            {
                DebugService = debugService;
            }

            public void SetSourceCode(SourceCode sourceCode)
            {
                
            }

            public void SetByteCode(string[] byteCode)
            {
                ByteCodes = byteCode;
            }

            public bool IsPauseRequested()
            {
                return true;
            }
            
            public void SignalExecutionEnded() { }

            public void Update(WatchType watchType, IEnumerable<WatchItem> items)
            {
                Watches[watchType] = items;
            }

            public List<DynamicExpression> GetWatchItems()
            {
                return m_Dynamics;
            }

            public void RefreshBreakpoints(IEnumerable<SourceRef> refs) { }
        }
    }
}