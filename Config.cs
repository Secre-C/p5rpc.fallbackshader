using System.ComponentModel;
using p5rpc.fallbackshader.Template.Configuration;

namespace p5rpc.fallbackshader;

public class Config : Configurable<Config>
{
    public enum PrintMode
    {
        Off,
        Info,
        Hash
    }
    /*
        User Properties:
            - Please put all of your configurable properties here.

        By default, configuration saves as "Config.json" in mod user config folder.
        Need more config files/classes? See Configuration.cs

        Available Attributes:
        - Category
        - DisplayName
        - Description
        - DefaultValue

        // Technically Supported but not Useful
        - Browsable
        - Localizable

        The `DefaultValue` attribute is used as part of the `Reset` button in Reloaded-Launcher.
    */

    [DisplayName("Debug Printing")]
    [Description("Enable Debug Printing.")]
    [DefaultValue(false)]
    public bool Debug { get; set; } = false;

    [DisplayName("Compile Shaders")]
    [Description("Compile shaders instead of using a fallback.")]
    [DefaultValue(true)]
    public bool Compile { get; set; } = true;

    [DisplayName("Output Shaders to File")]
    [Description("Output compiled shaders to file (found in this mods \"compiled\" folder)")]
    [DefaultValue(false)]
    public bool Output { get; set; } = false;
    
    [DisplayName("Print Mode")]
    [Description("Mode for Printing Missing Shaders")]
    [DefaultValue(PrintMode.Off)]
    public PrintMode Mode { get; set; } = PrintMode.Off;
}

/// <summary>
///     Allows you to override certain aspects of the configuration creation process (e.g. create multiple configurations).
///     Override elements in <see cref="ConfiguratorMixinBase" /> for finer control.
/// </summary>
public class ConfiguratorMixin : ConfiguratorMixinBase
{
    // 
}