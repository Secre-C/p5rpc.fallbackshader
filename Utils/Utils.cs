using p5rpc.fallbackshader.Template;
using Reloaded.Memory.SigScan.ReloadedII.Interfaces;

namespace p5rpc.fallbackshader.Utils;
internal static class Utils
{
    internal static void Initialize(ModContext context)
    {
        if (context.ModLoader.GetController<IStartupScanner>().TryGetTarget(out var scanner))
        {
            Scanner.scanner = scanner;
        }

        Logger.logger = context.Logger;
        Logger.Debug = context.Configuration.Debug;
    }
}
