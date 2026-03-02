using mRemoteNG.Config.Serializers.ConnectionSerializers.Rdp;
using mRemoteNG.Connection;
using mRemoteNG.Connection.Protocol;
using mRemoteNG.Connection.Protocol.RDP;
using mRemoteNG.Container;
using mRemoteNG.Security;
using mRemoteNG.Tree;
using mRemoteNG.Tree.Root;
using NUnit.Framework;

namespace mRemoteNGTests.Config.Serializers.ConnectionSerializers.Rdp;

public class RdpConnectionSerializerTests
{
    private RdpConnectionSerializer _sut = null!;

    [SetUp]
    public void Setup()
    {
        _sut = new RdpConnectionSerializer(new SaveFilter(true)
        {
            SaveUsername = true,
            SaveDomain = true
        });
    }

    [Test]
    public void Serialize_BasicConnection_ContainsHostnameAndPort()
    {
        var con = new ConnectionInfo { Hostname = "server1.example.com", Port = 3389 };

        string result = _sut.Serialize(con);

        Assert.That(result, Does.Contain("full address:s:server1.example.com"));
        Assert.That(result, Does.Contain("server port:i:3389"));
    }

    [Test]
    public void Serialize_WithUsername_ContainsUsername()
    {
        var con = new ConnectionInfo { Username = "admin" };

        string result = _sut.Serialize(con);

        Assert.That(result, Does.Contain("username:s:admin"));
    }

    [Test]
    public void Serialize_WithoutUsername_OmitsUsername()
    {
        var con = new ConnectionInfo { Username = "" };

        string result = _sut.Serialize(con);

        Assert.That(result, Does.Not.Contain("username:s:"));
    }

    [Test]
    public void Serialize_WithDomain_ContainsDomain()
    {
        var con = new ConnectionInfo { Domain = "CORP" };

        string result = _sut.Serialize(con);

        Assert.That(result, Does.Contain("domain:s:CORP"));
    }

    [Test]
    public void Serialize_SaveFilterBlocksUsername_OmitsUsername()
    {
        var sut = new RdpConnectionSerializer(new SaveFilter(true) { SaveUsername = false, SaveDomain = true });
        var con = new ConnectionInfo { Username = "admin" };

        string result = sut.Serialize(con);

        Assert.That(result, Does.Not.Contain("username:s:"));
    }

    [Test]
    public void Serialize_FullscreenResolution_SetsScreenMode2()
    {
        var con = new ConnectionInfo { Resolution = RDPResolutions.Fullscreen };

        string result = _sut.Serialize(con);

        Assert.That(result, Does.Contain("screen mode id:i:2"));
    }

    [Test]
    public void Serialize_FitToWindow_SetsSmartSizing()
    {
        var con = new ConnectionInfo { Resolution = RDPResolutions.FitToWindow };

        string result = _sut.Serialize(con);

        Assert.That(result, Does.Contain("screen mode id:i:1"));
        Assert.That(result, Does.Contain("smart sizing:i:1"));
    }

    [Test]
    public void Serialize_SpecificResolution_SetsWidthAndHeight()
    {
        var con = new ConnectionInfo { Resolution = RDPResolutions.Res1920x1080 };

        string result = _sut.Serialize(con);

        Assert.That(result, Does.Contain("desktopwidth:i:1920"));
        Assert.That(result, Does.Contain("desktopheight:i:1080"));
    }

    [Test]
    public void Serialize_DisplaySettings_WritesAllSettings()
    {
        var con = new ConnectionInfo
        {
            DisplayWallpaper = true,
            DisplayThemes = false,
            DisableFullWindowDrag = true,
            EnableFontSmoothing = true,
            CacheBitmaps = true,
            RedirectClipboard = true,
            RedirectPrinters = false
        };

        string result = _sut.Serialize(con);

        Assert.That(result, Does.Contain("disable wallpaper:i:0")); // inverted: wallpaper enabled = 0
        Assert.That(result, Does.Contain("disable themes:i:1"));
        Assert.That(result, Does.Contain("disable full window drag:i:1"));
        Assert.That(result, Does.Contain("allow font smoothing:i:1"));
        Assert.That(result, Does.Contain("bitmapcachepersistenable:i:1"));
        Assert.That(result, Does.Contain("redirectclipboard:i:1"));
        Assert.That(result, Does.Contain("redirectprinters:i:0"));
    }

    [Test]
    public void Serialize_WithLoadBalanceInfo_ContainsLoadBalanceInfo()
    {
        var con = new ConnectionInfo { LoadBalanceInfo = "tsv://MS Terminal Services Plugin.1.Sessions" };

        string result = _sut.Serialize(con);

        Assert.That(result, Does.Contain("loadbalanceinfo:s:tsv://MS Terminal Services Plugin.1.Sessions"));
    }

    [Test]
    public void Serialize_WithGateway_ContainsGatewaySettings()
    {
        var con = new ConnectionInfo
        {
            RDGatewayUsageMethod = RDGatewayUsageMethod.Always,
            RDGatewayHostname = "gateway.example.com"
        };

        string result = _sut.Serialize(con);

        Assert.That(result, Does.Contain("gatewayusagemethod:i:"));
        Assert.That(result, Does.Contain("gatewayhostname:s:gateway.example.com"));
        Assert.That(result, Does.Contain("gatewayprofileusagemethod:i:1"));
    }

    [Test]
    public void Serialize_WithStartProgram_ContainsShellAndWorkDir()
    {
        var con = new ConnectionInfo
        {
            RDPStartProgram = @"C:\Tools\app.exe",
            RDPStartProgramWorkDir = @"C:\Tools"
        };

        string result = _sut.Serialize(con);

        Assert.That(result, Does.Contain(@"alternate shell:s:C:\Tools\app.exe"));
        Assert.That(result, Does.Contain(@"shell working directory:s:C:\Tools"));
    }

    [Test]
    public void Serialize_Container_FindsFirstRdpConnection()
    {
        var container = new ContainerInfo();
        var sshConnection = new ConnectionInfo { Hostname = "ssh-server", Protocol = ProtocolType.SSH2 };
        var rdpConnection = new ConnectionInfo { Hostname = "rdp-server", Protocol = ProtocolType.RDP, Port = 3389 };
        container.AddChild(sshConnection);
        container.AddChild(rdpConnection);

        string result = _sut.Serialize(container);

        Assert.That(result, Does.Contain("full address:s:rdp-server"));
    }

    [Test]
    public void Serialize_ContainerWithNoRdp_FindsFirstConnection()
    {
        var container = new ContainerInfo();
        var sshConnection = new ConnectionInfo { Hostname = "ssh-server", Protocol = ProtocolType.SSH2, Port = 22 };
        container.AddChild(sshConnection);

        string result = _sut.Serialize(container);

        Assert.That(result, Does.Contain("full address:s:ssh-server"));
    }

    [Test]
    public void Serialize_EmptyContainer_ReturnsEmpty()
    {
        var container = new ContainerInfo();

        string result = _sut.Serialize(container);

        Assert.That(result, Is.Empty);
    }

    [Test]
    public void Serialize_ConnectionTreeModel_FindsRdpFromRoot()
    {
        var tree = new ConnectionTreeModel();
        var root = new RootNodeInfo(RootNodeType.Connection);
        var rdpConnection = new ConnectionInfo { Hostname = "tree-rdp", Protocol = ProtocolType.RDP, Port = 3389 };
        root.AddChild(rdpConnection);
        tree.AddRootNode(root);

        string result = _sut.Serialize(tree);

        Assert.That(result, Does.Contain("full address:s:tree-rdp"));
    }

    [TestCase(RDPResolutions.Res800x600, "desktopwidth:i:800", "desktopheight:i:600")]
    [TestCase(RDPResolutions.Res1280x1024, "desktopwidth:i:1280", "desktopheight:i:1024")]
    [TestCase(RDPResolutions.Res3840x2160, "desktopwidth:i:3840", "desktopheight:i:2160")]
    public void Serialize_VariousResolutions_SetsCorrectDimensions(RDPResolutions resolution, string expectedWidth, string expectedHeight)
    {
        var con = new ConnectionInfo { Resolution = resolution };

        string result = _sut.Serialize(con);

        Assert.That(result, Does.Contain(expectedWidth));
        Assert.That(result, Does.Contain(expectedHeight));
    }
}
