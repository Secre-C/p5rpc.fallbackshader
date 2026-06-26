using System.Diagnostics;
using System.Runtime.InteropServices;
using p5rpc.fallbackshader.Utils;
using Reloaded.Hooks.Definitions;
using Reloaded.Hooks.Definitions.Enums;

namespace p5rpc.fallbackshader;

public class FallbackShader
{
    private readonly Config config;
    
    private unsafe gfdGlobalGraphics* _gfdGlobal;
    
    private unsafe delegate GfdShaderFragment* DGfdShaderFragmentClone(GfdShaderFragment* gfdShaderFragment);
    private DGfdShaderFragmentClone _gfdShaderFragmentClone;
    
    private unsafe delegate void DGfdMutexLock(uint* pMutex);
    private DGfdMutexLock _gfdMutexLock;

    private unsafe delegate void DGfdMutexUnlock(uint* pMutex);
    private DGfdMutexUnlock _gfdMutexUnlock;
    
    private unsafe delegate GfdShaderFragment* DGfdShaderSearchFromId(GfdShaderID* pId);
    private DGfdShaderSearchFromId _gfdShaderSearchFromId;

    private unsafe delegate void Dfun140193460(int a1);
    private Dfun140193460 _fun140193460;
    
    private unsafe delegate GfdShaderFragment* DGfdShaderFragmentCreateFromId(GfdShaderID* pId);
    private IHook<DGfdShaderFragmentCreateFromId> _gfdShaderFragmentCreateFromIdHook;
    
    internal unsafe FallbackShader(IReloadedHooks hooks, Config config)
    {
        this.config = config;

        Scanner.SigScan("48 8D 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? 48 8B CB E8 ?? ?? ?? ?? 48 85 C0 75", "gfdGlobalRef", (result) => // 0x14021c189
        {
            _gfdGlobal = (gfdGlobalGraphics*)(Memory.GetAddressFromGlobalRef(result, 7, "gfdGlobal") - 0xA38);
            Logger.DebugLog($"gfdGlobal -> 0x{(long)_gfdGlobal:X8}");
        });
        
        Scanner.SigScan("48 89 5C 24 ?? 48 89 74 24 ?? 57 48 83 EC 20 48 8B D9 B9 38 00 00 00", "gfdShaderFragmentClone", (result) => // 0x14021be70
        {
            _gfdShaderFragmentClone = hooks.CreateWrapper<DGfdShaderFragmentClone>(result, out var address);
        });
        
        Scanner.SigScan("E8 ?? ?? ?? ?? 48 8B CB E8 ?? ?? ?? ?? 48 85 C0 75 ?? 48 8D 0D", "gfdMutexLockRef", (result) => // 0x14021c190
        {
            result = Memory.GetAddressFromGlobalRef(result, 5, "gfdMutexLock");
            _gfdMutexLock = hooks.CreateWrapper<DGfdMutexLock>(result, out var address);
        });
        
        Scanner.SigScan("E8 ?? ?? ?? ?? 48 8B C3 48 83 C4 20 5B C3 B9 38 00 00 00", "gfdMutexUnlockRef", (result) => // 0x14021c1ed
        {
            result = Memory.GetAddressFromGlobalRef(result, 5, "gfdMutexUnlock");
            _gfdMutexUnlock = hooks.CreateWrapper<DGfdMutexUnlock>(result, out var address);
        });
        
        Scanner.SigScan("48 89 5C 24 ?? 48 89 6C 24 ?? 48 89 74 24 ?? 57 41 54 41 55 41 56 41 57 48 83 EC 40 48 8B 05 ?? ?? ?? ?? 4C 8D 2D", "gfdShaderSearchFromID", (result) => // 0x14021c360
        {
            _gfdShaderSearchFromId = hooks.CreateWrapper<DGfdShaderSearchFromId>(result, out var address);
        });
        
        Scanner.SigScan("44 8B C1 B8 D3 4D 62 10", "FUN_140193460", (result) => // 0x140193460
        {
            _fun140193460 = hooks.CreateWrapper<Dfun140193460>(result, out var address);
        });
        
        Scanner.SigScan("40 53 48 83 EC 20 48 8B D9 48 8D 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? 48 8B CB E8", "gfdShaderFragmentCreateFromID", (result) => // 0x14021c180
        {
            _gfdShaderFragmentCreateFromIdHook = hooks.CreateHook<DGfdShaderFragmentCreateFromId>((GfdShaderID* pId) =>
            {
                var shaderIndex = 0xc5;
                var shaders= &_gfdGlobal->shaderFragment;
                var mutex = &_gfdGlobal->shaderMutex;

                _gfdMutexLock(mutex);
                var foundShader = _gfdShaderSearchFromId(pId);
                
                while( true ) {
                    if (foundShader != (void*)0x0) {
                        foundShader = _gfdShaderFragmentClone(foundShader);
                        _gfdMutexUnlock(mutex);
                        return foundShader;
                    }
                    _gfdMutexUnlock(mutex);
                    if (_gfdGlobal->Field_0x2348 == 0) break;
                    _fun140193460(8000);
                    _gfdMutexLock(mutex);
                    foundShader = _gfdShaderSearchFromId(pId);
                }
                
                if (config.PrintShaders && pId != null)
                    Logger.Log(pId->ToString());
                
                while (true)
                {
                    var fallback = shaders[shaderIndex];
                    if (fallback != (void*)0x0)
                    {
                        _gfdMutexLock(mutex);
                        var fallbackShader = _gfdShaderFragmentClone(fallback);
                        _gfdMutexUnlock(mutex);
                        return fallbackShader;   
                    }
                }
            }, result).Activate();
        });
    }
}