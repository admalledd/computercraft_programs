using System;
using System.Linq;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MoonSharp.Interpreter;
using MoonSharp.Interpreter.Platforms;

namespace server_v2.Tests
{
    [TestClass]
    public class AssemblyInit
    {
        [AssemblyInitialize]
        public static void TestAssemblyInit(TestContext testContext)
        {
            Script.GlobalOptions.Platform = new LimitedPlatformAccessor();
            Script.DefaultOptions.DebugPrint = s => System.Diagnostics.Trace.WriteLine(s);
            Script.DefaultOptions.DebugInput = null;
            Script.DefaultOptions.ScriptLoader = null; //Hrm, maybe want one that "can" boot/load from `lua_files/swarm`?
            Script.DefaultOptions.Stderr = null;
            Script.DefaultOptions.Stdin = null;
            Script.DefaultOptions.Stdout = null;
            
            UserData.DefaultAccessMode = InteropAccessMode.BackgroundOptimized;
            UserData.RegistrationPolicy = new MSTypeRegistrationPolicy();
            
        }

        private class MSTypeRegistrationPolicy : MoonSharp.Interpreter.Interop.RegistrationPolicies.DefaultRegistrationPolicy
        {
            public override bool AllowTypeAutoRegistration(Type type)
            {
                //base is always false for Default, so ignore it's super
                var safe_namespaces = new[]
                {
                    "server_v2"
                };
                var safe_fullNames = new[]
                {
                    "System.DateTime"
                };
                if (safe_namespaces.Any(a => type.Namespace?.StartsWith(a) ?? false))
                {
                    return true;
                }

                if (safe_fullNames.Any(a => type.FullName == a))
                {
                    return true;
                }

                return false;
            }
        }
    }
}