using p5rpc.fallbackshader.Utils;
using Reloaded.Hooks.Definitions;

namespace p5rpc.fallbackshader;

public static unsafe class FallbackShader
{
    internal static IReloadedHooks hooks;
    internal static Config config;
    internal static string modDir;

    internal static gfdGlobalGraphics* _gfdGlobal;
    internal static DGfdMutexLock _gfdMutexLock;
    internal static DGfdMutexUnlock _gfdMutexUnlock;
    internal static Dfun140193460 _fun140193460;

    internal static GfdShaderFragmentFallback _fragmentFallback;
    internal static GfdShaderVertexFallback _vertexFallback;
    internal static DGfdShaderVertexCreate _gfdShaderVertexCreate;

    internal static string? GetShaderIdString(GfdShaderID* pId)
    {
        switch (config.Mode)
        {
            case Config.PrintMode.Info:
                return pId->ToString();
            case Config.PrintMode.Hash:
                return pId->GetHashCode();
        }

        return null;
    }

    internal static void GetGfdCommonFuncs(IReloadedHooks hooks, Config config, string modDir)
    {
        FallbackShader.hooks = hooks;
        FallbackShader.config = config;
        FallbackShader.modDir = modDir;

        Scanner.SigScan("48 8D 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? 48 8B CB E8 ?? ?? ?? ?? 48 85 C0 75", "gfdGlobalRef",
            result => // 0x14021c189
            {
                _gfdGlobal = (gfdGlobalGraphics*)(Memory.GetAddressFromGlobalRef(result, 7, "gfdGlobal") - 0xA38);
                Logger.DebugLog($"gfdGlobal -> 0x{(long)_gfdGlobal:X8}");
            });

        Scanner.SigScan("E8 ?? ?? ?? ?? 48 8B CB E8 ?? ?? ?? ?? 48 85 C0 75 ?? 48 8D 0D", "gfdMutexLockRef",
            result => // 0x14021c190
            {
                result = Memory.GetAddressFromGlobalRef(result, 5, "gfdMutexLock");
                _gfdMutexLock = hooks.CreateWrapper<DGfdMutexLock>(result, out var address);
            });

        Scanner.SigScan("E8 ?? ?? ?? ?? 48 8B C3 48 83 C4 20 5B C3 B9 38 00 00 00", "gfdMutexUnlockRef",
            result => // 0x14021c1ed
            {
                result = Memory.GetAddressFromGlobalRef(result, 5, "gfdMutexUnlock");
                _gfdMutexUnlock = hooks.CreateWrapper<DGfdMutexUnlock>(result, out var address);
            });

        Scanner.SigScan("44 8B C1 B8 D3 4D 62 10", "FUN_140193460", result => // 0x140193460
        {
            _fun140193460 = hooks.CreateWrapper<Dfun140193460>(result, out var address);
        });

        _fragmentFallback = new GfdShaderFragmentFallback();
        _vertexFallback = new GfdShaderVertexFallback();
    }

    internal delegate void DGfdMutexLock(uint* pMutex);

    internal delegate void DGfdMutexUnlock(uint* pMutex);

    internal delegate void Dfun140193460(int a1);

    internal delegate GfdShaderVertex* DGfdShaderVertexCreate(GfdShaderID* pId, byte[] code, int size);
}