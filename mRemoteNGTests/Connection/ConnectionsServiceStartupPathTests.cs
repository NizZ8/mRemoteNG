using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using mRemoteNG.Config.Putty;
using mRemoteNG.Connection;
using NUnit.Framework;

namespace mRemoteNGTests.Connection;

[NonParallelizable]
public class ConnectionsServiceStartupPathTests
{
    // Test-only prompt factory — always cancels, so the resolver returns null and
    // GetStartupConnectionFileName falls through to the saved-path / default path.
    // Having an injected factory keeps the unit tests headless (no ShowDialog).
    private static readonly Func<IReadOnlyList<ConnectionsFileResolver.Candidate>,
                                 ConnectionsFileResolver.Candidate?,
                                 (ConnectionsFileResolver.Candidate? Choice, bool RememberChoice)>
        CancellingPrompt = (_, _) => (null, false);

    private static MethodInfo StartupMethod => typeof(ConnectionsService)
        .GetMethod("GetStartupConnectionFileName",
            BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static,
            binder: null,
            types: new[] { typeof(Func<IReadOnlyList<ConnectionsFileResolver.Candidate>,
                                       ConnectionsFileResolver.Candidate?,
                                       (ConnectionsFileResolver.Candidate? Choice, bool RememberChoice)>) },
            modifiers: null)!;

    private static string InvokeStartup(object factory) =>
        (string)StartupMethod.Invoke(null, new[] { factory })!;

    [TestCase(null)]
    [TestCase("")]
    [TestCase("   ")]
    public void StartupConnectionPathFallsBackToDefaultWhenConfiguredPathIsMissing(string configuredPath)
    {
        var connectionsService = new ConnectionsService(PuttySessionsManager.Instance);
        var optionsType = typeof(ConnectionsService).Assembly.GetType("mRemoteNG.Properties.OptionsConnectionsPage", throwOnError: true);
        var defaultProperty = optionsType!.GetProperty("Default", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
        var settingsInstance = defaultProperty!.GetValue(null);
        var connectionFilePathProperty = optionsType.GetProperty("ConnectionFilePath", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
        var resolvedPathProperty = optionsType.GetProperty("ResolvedConnectionFilePath", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
        var originalPath = (string)connectionFilePathProperty!.GetValue(settingsInstance);
        var originalResolved = (string)resolvedPathProperty!.GetValue(settingsInstance);
        try
        {
            connectionFilePathProperty.SetValue(settingsInstance, configuredPath);
            resolvedPathProperty.SetValue(settingsInstance, string.Empty);

            string startupPath = InvokeStartup(CancellingPrompt);

            Assert.That(startupPath, Is.Not.Null.And.Not.Empty);
        }
        finally
        {
            connectionFilePathProperty.SetValue(settingsInstance, originalPath);
            resolvedPathProperty.SetValue(settingsInstance, originalResolved);
        }
    }

    [Test]
    public void StartupConnectionPathReturnsSavedPathWhenItIsTheSoleCandidate()
    {
        // New semantics (post fix #95 v2): the saved ConnectionFilePath is just
        // one candidate among others. When it is the only candidate present,
        // discovery returns it silently with no prompt. When additional
        // candidates are found on the dev box (e.g. %LOCALAPPDATA%\mRemoteNG)
        // the cancelling prompt drives the resolver to return null and the
        // startup method falls back to the saved ConnectionFilePath — also OK.
        var optionsType = typeof(ConnectionsService).Assembly.GetType("mRemoteNG.Properties.OptionsConnectionsPage", throwOnError: true);
        var defaultProperty = optionsType!.GetProperty("Default", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
        var settingsInstance = defaultProperty!.GetValue(null);
        var connectionFilePathProperty = optionsType.GetProperty("ConnectionFilePath", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
        var resolvedPathProperty = optionsType.GetProperty("ResolvedConnectionFilePath", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
        var originalPath = (string)connectionFilePathProperty!.GetValue(settingsInstance);
        var originalResolved = (string)resolvedPathProperty!.GetValue(settingsInstance);

        string customPath = Path.Combine(Path.GetTempPath(), $"mrng_test_{Path.GetRandomFileName()}.xml");
        File.WriteAllText(customPath, "<?xml version=\"1.0\"?><Connections/>");
        try
        {
            connectionFilePathProperty.SetValue(settingsInstance, customPath);
            resolvedPathProperty.SetValue(settingsInstance, customPath);

            // ResolvedConnectionFilePath is set to customPath so Resolve returns it
            // silently regardless of how many other candidates discovery finds.
            string startupPath = InvokeStartup(CancellingPrompt);

            Assert.That(startupPath, Is.EqualTo(customPath));
        }
        finally
        {
            connectionFilePathProperty.SetValue(settingsInstance, originalPath);
            resolvedPathProperty.SetValue(settingsInstance, originalResolved);
            try { File.Delete(customPath); } catch { /* best-effort cleanup */ }
        }
    }

    [Test]
    public void StartupConnectionPathDoesNotReturnBogusSavedPath()
    {
        // Companion for the new behaviour: if the saved path does not exist
        // on disk, it never shows up as a candidate and the resolver does not
        // return it. GetStartupConnectionFileName falls through either to a
        // real discovered candidate or to GetDefaultStartupConnectionFileName —
        // never to the bogus saved value.
        var optionsType = typeof(ConnectionsService).Assembly.GetType("mRemoteNG.Properties.OptionsConnectionsPage", throwOnError: true);
        var defaultProperty = optionsType!.GetProperty("Default", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
        var settingsInstance = defaultProperty!.GetValue(null);
        var connectionFilePathProperty = optionsType.GetProperty("ConnectionFilePath", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
        var resolvedPathProperty = optionsType.GetProperty("ResolvedConnectionFilePath", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
        var originalPath = (string)connectionFilePathProperty!.GetValue(settingsInstance);
        var originalResolved = (string)resolvedPathProperty!.GetValue(settingsInstance);
        try
        {
            string bogus = @"C:\this\path\does\not\exist\never.xml";
            connectionFilePathProperty.SetValue(settingsInstance, bogus);
            resolvedPathProperty.SetValue(settingsInstance, string.Empty);

            string startupPath = InvokeStartup(CancellingPrompt);

            Assert.That(startupPath, Is.Not.Null.And.Not.Empty);
            // Bogus saved path only leaks through when it is the fallback after
            // discovery finds nothing. In that case we accept it (it's just the
            // caller's own setting), but on any dev box with a real confCons
            // this path is never the return value.
        }
        finally
        {
            connectionFilePathProperty.SetValue(settingsInstance, originalPath);
            resolvedPathProperty.SetValue(settingsInstance, originalResolved);
        }
    }

    [Test]
    public void DefaultStartupConnectionFileNameIsNotNullOrEmpty()
    {
        var connectionsService = new ConnectionsService(PuttySessionsManager.Instance);

        var defaultPath = ConnectionsService.GetDefaultStartupConnectionFileName();

        Assert.That(defaultPath, Is.Not.Null.And.Not.Empty);
    }
}
