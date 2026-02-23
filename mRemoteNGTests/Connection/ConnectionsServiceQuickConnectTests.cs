using mRemoteNG.Config.Putty;
using mRemoteNG.Connection;
using mRemoteNG.Connection.Protocol;
using NUnit.Framework;

namespace mRemoteNGTests.Connection;

[NonParallelizable]
public class ConnectionsServiceQuickConnectTests
{
    private string _originalDefaultUsername = string.Empty;

    [SetUp]
    public void SetUp()
    {
        _originalDefaultUsername = DefaultConnectionInfo.Instance.Username;
    }

    [TearDown]
    public void TearDown()
    {
        DefaultConnectionInfo.Instance.Username = _originalDefaultUsername;
    }

    [Test]
    public void CreateQuickConnectUsesExplicitUsernameWhenProvided()
    {
        DefaultConnectionInfo.Instance.Username = "root";
        var connectionsService = new ConnectionsService(PuttySessionsManager.Instance);

        ConnectionInfo? quickConnect = connectionsService.CreateQuickConnect("myUser@example-host", ProtocolType.SSH2);

        Assert.That(quickConnect, Is.Not.Null);
        Assert.Multiple(() =>
        {
            Assert.That(quickConnect!.Hostname, Is.EqualTo("example-host"));
            Assert.That(quickConnect.Username, Is.EqualTo("myUser"));
        });
    }

    [Test]
    public void CreateQuickConnectKeepsDefaultUsernameWhenNoOverrideProvided()
    {
        DefaultConnectionInfo.Instance.Username = "root";
        var connectionsService = new ConnectionsService(PuttySessionsManager.Instance);

        ConnectionInfo? quickConnect = connectionsService.CreateQuickConnect("example-host", ProtocolType.SSH2);

        Assert.That(quickConnect, Is.Not.Null);
        Assert.That(quickConnect!.Username, Is.EqualTo("root"));
    }

    [Test]
    public void CreateQuickConnectUsesExplicitUsernameAndPortWhenProvided()
    {
        DefaultConnectionInfo.Instance.Username = "root";
        var connectionsService = new ConnectionsService(PuttySessionsManager.Instance);

        ConnectionInfo? quickConnect = connectionsService.CreateQuickConnect("myUser@example-host:2200", ProtocolType.SSH2);

        Assert.That(quickConnect, Is.Not.Null);
        Assert.Multiple(() =>
        {
            Assert.That(quickConnect!.Hostname, Is.EqualTo("example-host"));
            Assert.That(quickConnect.Port, Is.EqualTo(2200));
            Assert.That(quickConnect.Username, Is.EqualTo("myUser"));
        });
    }

    [Test]
    public void CreateQuickConnectKeepsLegacyHostAndPortFormat()
    {
        DefaultConnectionInfo.Instance.Username = "root";
        var connectionsService = new ConnectionsService(PuttySessionsManager.Instance);

        ConnectionInfo? quickConnect = connectionsService.CreateQuickConnect("example-host:2200", ProtocolType.SSH2);

        Assert.That(quickConnect, Is.Not.Null);
        Assert.Multiple(() =>
        {
            Assert.That(quickConnect!.Hostname, Is.EqualTo("example-host"));
            Assert.That(quickConnect.Port, Is.EqualTo(2200));
            Assert.That(quickConnect.Username, Is.EqualTo("root"));
        });
    }

    [Test]
    public void CreateQuickConnectReturnsNullWhenHostnameIsEmpty()
    {
        var connectionsService = new ConnectionsService(PuttySessionsManager.Instance);

        ConnectionInfo? quickConnect = connectionsService.CreateQuickConnect("   ", ProtocolType.SSH2);

        Assert.That(quickConnect, Is.Null);
    }

    [Test]
    public void CreateQuickConnectRdpFlagDisablesRestrictedAdmin()
    {
        var connectionsService = new ConnectionsService(PuttySessionsManager.Instance);

        ConnectionInfo? quickConnect = connectionsService.CreateQuickConnect("myserver -ra:false", ProtocolType.RDP);

        Assert.That(quickConnect, Is.Not.Null);
        Assert.Multiple(() =>
        {
            Assert.That(quickConnect!.Hostname, Is.EqualTo("myserver"));
            Assert.That(quickConnect.UseRestrictedAdmin, Is.False);
        });
    }

    [Test]
    public void CreateQuickConnectRdpFlagEnablesRestrictedAdmin()
    {
        var connectionsService = new ConnectionsService(PuttySessionsManager.Instance);

        ConnectionInfo? quickConnect = connectionsService.CreateQuickConnect("myserver -ra:true", ProtocolType.RDP);

        Assert.That(quickConnect, Is.Not.Null);
        Assert.That(quickConnect!.UseRestrictedAdmin, Is.True);
    }

    [Test]
    public void CreateQuickConnectRdpFlagDisablesRCG()
    {
        var connectionsService = new ConnectionsService(PuttySessionsManager.Instance);

        ConnectionInfo? quickConnect = connectionsService.CreateQuickConnect("myserver -rcg:false", ProtocolType.RDP);

        Assert.That(quickConnect, Is.Not.Null);
        Assert.Multiple(() =>
        {
            Assert.That(quickConnect!.Hostname, Is.EqualTo("myserver"));
            Assert.That(quickConnect.UseRCG, Is.False);
        });
    }

    [Test]
    public void CreateQuickConnectRdpFlagsBothDisabled()
    {
        var connectionsService = new ConnectionsService(PuttySessionsManager.Instance);

        ConnectionInfo? quickConnect = connectionsService.CreateQuickConnect("myserver -ra:false -rcg:false", ProtocolType.RDP);

        Assert.That(quickConnect, Is.Not.Null);
        Assert.Multiple(() =>
        {
            Assert.That(quickConnect!.Hostname, Is.EqualTo("myserver"));
            Assert.That(quickConnect.UseRestrictedAdmin, Is.False);
            Assert.That(quickConnect.UseRCG, Is.False);
        });
    }

    [Test]
    public void CreateQuickConnectRdpFlagsIgnoredForNonRdpProtocol()
    {
        // Default UseRestrictedAdmin is false; pass -ra:true — if correctly ignored for SSH2, result stays false
        var connectionsService = new ConnectionsService(PuttySessionsManager.Instance);

        ConnectionInfo? quickConnect = connectionsService.CreateQuickConnect("myserver -ra:true", ProtocolType.SSH2);

        Assert.That(quickConnect, Is.Not.Null);
        Assert.Multiple(() =>
        {
            Assert.That(quickConnect!.Hostname, Is.EqualTo("myserver"));
            // Flag is ignored for non-RDP; UseRestrictedAdmin keeps the default value (false)
            Assert.That(quickConnect.UseRestrictedAdmin, Is.False);
        });
    }

    [Test]
    public void CreateQuickConnectRdpFlagsWithUsernameAndPort()
    {
        var connectionsService = new ConnectionsService(PuttySessionsManager.Instance);

        ConnectionInfo? quickConnect = connectionsService.CreateQuickConnect("admin@myserver:3389 -ra:false -rcg:false", ProtocolType.RDP);

        Assert.That(quickConnect, Is.Not.Null);
        Assert.Multiple(() =>
        {
            Assert.That(quickConnect!.Hostname, Is.EqualTo("myserver"));
            Assert.That(quickConnect.Port, Is.EqualTo(3389));
            Assert.That(quickConnect.Username, Is.EqualTo("admin"));
            Assert.That(quickConnect.UseRestrictedAdmin, Is.False);
            Assert.That(quickConnect.UseRCG, Is.False);
        });
    }
}
