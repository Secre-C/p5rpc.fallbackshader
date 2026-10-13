using System.Drawing;
using Reloaded.Mod.Interfaces;

namespace p5rpc.fallbackshader.Utils;

internal static class Logger
{
    internal static ILogger? logger { get; set; }
    internal static bool Debug { get; set; }

    private static void LogAsync(string prefix, string message, Color color)
    {
        logger.WriteLineAsync($"{prefix} {message}", color);
    }

    private static void Log(string prefix, string message, Color color)
    {
        logger.WriteLine($"{prefix} {message}", color);
    }

    internal static void Log(string message, Color color)
    {
        LogAsync("[FallbackShader]", message, color);
    }

    internal static void Log(string message)
    {
        Log(message, Color.LightGray);
    }

    internal static void DebugLog(string message, Color color)
    {
        if (Debug)
            Log("[FallbackShader DEBUG]", message, color);
    }

    internal static void DebugLog(string message)
    {
        DebugLog(message, Color.LightCyan);
    }
}