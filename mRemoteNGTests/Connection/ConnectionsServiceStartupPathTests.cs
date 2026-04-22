using System.IO;
using System.Reflection;
using mRemoteNG.Config.Putty;
using mRemoteNG.Connection;
using NUnit.Framework;

namespace mRemoteNGTests.Connection;

[NonParallelizable]
public class ConnectionsServiceStartupPathTests
{
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
        var originalPath = (string)connectionFilePathProperty!.GetValue(settingsInstance);
        try
        {
            connectionFilePathProperty.SetValue(settingsInstance, configuredPath);

            var startupPath = ConnectionsService.GetStartupConnectionFileName();
            var defaultPath = ConnectionsService.GetDefaultStartupConnectionFileName();

            Assert.That(startupPath, Is.EqualTo(defaultPath));
        }
        finally
        {
            connectionFilePathProperty.SetValue(settingsInstance, originalPath);
        }
    }

    [Test]
    public void StartupConnectionPathReturnsConfiguredPathWhenSet()
    {
        var connectionsService = new ConnectionsService(PuttySessionsManager.Instance);
        var optionsType = typeof(ConnectionsService).Assembly.GetType("mRemoteNG.Properties.OptionsConnectionsPage", throwOnError: true);
        var defaultProperty = optionsType!.GetProperty("Default", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
        var settingsInstance = defaultProperty!.GetValue(null);
        var connectionFilePathProperty = optionsType.GetProperty("ConnectionFilePath", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
        var originalPath = (string)connectionFilePathProperty!.GetValue(settingsInstance);

        // The resolver now verifies that the configured path still exists before
        // returning it; otherwise it falls back to candidate discovery (#95). Create
        // a real temp file so the test asserts the "configured + existing" branch.
        string customPath = Path.Combine(Path.GetTempPath(), $"mrng_test_{Path.GetRandomFileName()}.xml");
        File.WriteAllText(customPath, "<?xml version=\"1.0\"?><Connections/>");
        try
        {
            connectionFilePathProperty.SetValue(settingsInstance, customPath);

            var startupPath = ConnectionsService.GetStartupConnectionFileName();

            Assert.That(startupPath, Is.EqualTo(customPath));
        }
        finally
        {
            connectionFilePathProperty.SetValue(settingsInstance, originalPath);
            try { File.Delete(customPath); } catch { /* best-effort cleanup */ }
        }
    }

    [Test]
    public void StartupConnectionPathFallsBackWhenConfiguredPathMissing()
    {
        // Companion assertion for the new behaviour: if the saved path no longer
        // exists on disk, the resolver does NOT return it blindly. It returns
        // either a discovered candidate or the edition default — either way,
        // not the bogus saved value.
        var connectionsService = new ConnectionsService(PuttySessionsManager.Instance);
        var optionsType = typeof(ConnectionsService).Assembly.GetType("mRemoteNG.Properties.OptionsConnectionsPage", throwOnError: true);
        var defaultProperty = optionsType!.GetProperty("Default", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
        var settingsInstance = defaultProperty!.GetValue(null);
        var connectionFilePathProperty = optionsType.GetProperty("ConnectionFilePath", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
        var originalPath = (string)connectionFilePathProperty!.GetValue(settingsInstance);
        try
        {
            string bogus = @"C:\this\path\does\not\exist\never.xml";
            connectionFilePathProperty.SetValue(settingsInstance, bogus);

            var startupPath = ConnectionsService.GetStartupConnectionFileName();

            Assert.That(startupPath, Is.Not.EqualTo(bogus));
            Assert.That(startupPath, Is.Not.Null.And.Not.Empty);
        }
        finally
        {
            connectionFilePathProperty.SetValue(settingsInstance, originalPath);
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
