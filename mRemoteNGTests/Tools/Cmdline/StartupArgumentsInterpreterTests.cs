using System;
using System.Reflection;
using mRemoteNG.Messages;
using mRemoteNG.Tools.Cmdline;
using NUnit.Framework;

namespace mRemoteNGTests.Tools.Cmdline
{
    public class StartupArgumentsInterpreterTests
    {
        private static readonly string[] ConnectArgs = ["mRemoteNG.exe", "--connect", "ConnA"];
        private static readonly string[] StartupArgs = ["mRemoteNG.exe", "--startup", "ConnA"];

        [SetUp]
        public void SetUp()
        {
            SetStaticTarget(nameof(StartupArgumentsInterpreter.ConnectTo), null);
            SetStaticTarget(nameof(StartupArgumentsInterpreter.StartupConnectTo), null);
        }

        [Test]
        public void ParseArguments_SetsConnectTo_WhenConnectArgumentIsProvided()
        {
            var startupArgumentsInterpreter = CreateSut();

            startupArgumentsInterpreter.ParseArguments(ConnectArgs);

            Assert.That(StartupArgumentsInterpreter.ConnectTo, Is.EqualTo("ConnA"));
            Assert.That(StartupArgumentsInterpreter.StartupConnectTo, Is.Null);
        }

        [Test]
        public void ParseArguments_SetsStartupConnectTo_WhenStartupArgumentIsProvided()
        {
            var startupArgumentsInterpreter = CreateSut();

            startupArgumentsInterpreter.ParseArguments(StartupArgs);

            Assert.That(StartupArgumentsInterpreter.StartupConnectTo, Is.EqualTo("ConnA"));
            Assert.That(StartupArgumentsInterpreter.ConnectTo, Is.Null);
        }

        private static StartupArgumentsInterpreter CreateSut()
        {
            return new StartupArgumentsInterpreter(new MessageCollector());
        }

        private static void SetStaticTarget(string propertyName, string? value)
        {
            PropertyInfo property = typeof(StartupArgumentsInterpreter).GetProperty(propertyName,
                BindingFlags.Public | BindingFlags.Static) ?? throw new InvalidOperationException($"Could not find property '{propertyName}'.");
            MethodInfo setter = property.GetSetMethod(true) ?? throw new InvalidOperationException($"Property '{propertyName}' does not have a setter.");
            setter.Invoke(null, new object?[] { value });
        }
    }
}
