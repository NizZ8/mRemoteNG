using System.Configuration;
using mRemoteNG.Config.Settings.Providers;

// Ensure all settings classes use ChooseProvider (PortableSettingsProvider when PORTABLE
// is defined). This attribute-based wiring complements PortableSettingsInitializer's
// programmatic wiring, providing defense-in-depth against .NET 10 provider resolution
// issues that can cause settings to silently fall back to LocalFileSettingsProvider.
// See: https://github.com/robertpopa22/mRemoteNG/issues/71

namespace mRemoteNG.Properties
{
    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class App { }

    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class AppUI { }

    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class OptionsAdvancedPage { }

    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class OptionsAppearancePage { }

    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class OptionsBackupPage { }

    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class OptionsConnectionsPage { }

    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class OptionsCredentialsPage { }

    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class OptionsDBsPage { }

    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class OptionsGoogleDrivePage { }

    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class OptionsNotificationsPage { }

    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class OptionsRbac { }

    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class OptionsSecurityPage { }

    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class OptionsStartupExitPage { }

    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class OptionsTabsPanelsPage { }

    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class OptionsThemePage { }

    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class OptionsUpdatesPage { }

    // Note: Config\Settings\Settings.cs declares a partial class in namespace
    // mRemoteNG.Config.Settings — that is a DIFFERENT class and its attribute
    // does not apply to this one (mRemoteNG.Properties.Settings).
    [SettingsProvider(typeof(ChooseProvider))]
    internal sealed partial class Settings { }
}
