using p5rpc.fallbackshader.Utils;
using Reloaded.Hooks.Definitions;
using Vortice.D3DCompiler;
using static p5rpc.fallbackshader.FallbackShader;

namespace p5rpc.fallbackshader;

internal unsafe struct GfdShaderFragment
{
    internal ushort flags;
    internal ushort unk2;
    internal GfdShaderID id;
    internal void* device;
    internal GfdShaderFragment* prev;
    internal GfdShaderFragment* next;
}

internal unsafe class GfdShaderFragmentFallback
{
    private DGfdShaderFragmentClone _gfdShaderFragmentClone;

    private DGfdShaderFragmentCreate _gfdShaderFragmentCreate;
    private IHook<DGfdShaderFragmentCreateFromId> _gfdShaderFragmentCreateFromIdHook;
    private DGfdShaderFragmentSearchFromId _gfdShaderFragmentSearchFromId;

    internal GfdShaderFragmentFallback()
    {
        Scanner.SigScan("48 89 5C 24 ?? 48 89 74 24 ?? 57 48 83 EC 20 48 8B D9 B9 38 00 00 00",
            "gfdShaderFragmentClone", result => // 0x14021be70
            {
                _gfdShaderFragmentClone = hooks.CreateWrapper<DGfdShaderFragmentClone>(result, out var address);
            });

        Scanner.SigScan(
            "48 89 5C 24 ?? 48 89 6C 24 ?? 48 89 74 24 ?? 57 41 54 41 55 41 56 41 57 48 83 EC 40 48 8B 05 ?? ?? ?? ?? 4C 8D 2D",
            "gfdShaderSearchFromID", result => // 0x14021c360
            {
                _gfdShaderFragmentSearchFromId =
                    hooks.CreateWrapper<DGfdShaderFragmentSearchFromId>(result, out var address);
            });

        Scanner.SigScan("48 89 5C 24 ?? 48 89 6C 24 ?? 56 48 83 EC 20 48 8B D9 41 8B F0", "gfdShaderFragmentCreate",
            result => // 0x14021bfb0
            {
                _gfdShaderFragmentCreate = hooks.CreateWrapper<DGfdShaderFragmentCreate>(result, out var address);
            });

        Scanner.SigScan(
            "48 89 5C 24 ?? 48 89 6C 24 ?? 48 89 74 24 ?? 57 48 83 EC 20 41 8B F0 48 8B EA 48 8B F9 E8 ?? ?? ?? ?? 48 8B D8 48 85 C0 75",
            "gfdShaderVertexCreate", result => // 0x14021de30
            {
                _gfdShaderVertexCreate = hooks.CreateWrapper<DGfdShaderVertexCreate>(result, out var address);
            });

        Scanner.SigScan("40 53 48 83 EC 20 48 8B D9 48 8D 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? 48 8B CB E8",
            "gfdShaderFragmentCreateFromID", result => // 0x14021c180
            {
                _gfdShaderFragmentCreateFromIdHook = hooks.CreateHook<DGfdShaderFragmentCreateFromId>(
                    pId =>
                    {
                        var shaders = &_gfdGlobal->shaderFragment;
                        var mutex = &_gfdGlobal->shaderFragmentMutex;

                        _gfdMutexLock(mutex);
                        var foundShader = _gfdShaderFragmentSearchFromId(pId);

                        while (true)
                        {
                            if (foundShader != (void*)0x0)
                            {
                                foundShader = _gfdShaderFragmentClone(foundShader);
                                _gfdMutexUnlock(mutex);
                                return foundShader;
                            }

                            _gfdMutexUnlock(mutex);
                            if (_gfdGlobal->Field_0x2348 == 0) break;
                            _fun140193460(8000);
                            _gfdMutexLock(mutex);
                            foundShader = _gfdShaderFragmentSearchFromId(pId);
                        }

                        if (pId != null && config.Mode != Config.PrintMode.Off)
                            Logger.Log(pId->GetHashCode());

                        GfdShaderFragment* shader = null;
                        try
                        {
                            var pShaderSrc = Path.Join(modDir, "ShaderSrc", pId->type + "_ps.hlsl");
                            var shaderFlags = new ShaderFlags();
                            shaderFlags |= ShaderFlags.OptimizationLevel3;

                            var macros = gfdShaderDefines.GenerateShaderArgs(pId);
                            Logger.DebugLog("macros: " + macros.Length);

                            var pCode = D3DCompiler.CompileShader(pShaderSrc, "ps_5_0", macros, shaderFlags, config.Debug);
                            if (config.Output)
                                File.WriteAllBytes(Path.Join(modDir, "compiled", "Pixel_" + pId->GetHashCode() + ".bin"), pCode);

                            Logger.DebugLog("Dir: " + pShaderSrc);
                            Logger.DebugLog("Length: " + pCode.Length);
                            _gfdMutexLock(mutex);
                            shader = _gfdShaderFragmentCreate(pId, pCode, pCode.Length);
                            _gfdMutexUnlock(mutex);
                        }
                        catch (Exception e)
                        {
                            Logger.Log($"Failed to compile Pixel shader for {pId->GetHashCode()}: {e.Message}");
                            var shaderIndex = 0xc5;

                            while (true)
                            {
                                var fallback = shaders[shaderIndex];
                                if (fallback != (void*)0x0)
                                {
                                    _gfdMutexLock(mutex);
                                    shader = _gfdShaderFragmentClone(fallback);
                                    _gfdMutexUnlock(mutex);
                                    return shader;
                                }
                            }
                        }

                        return shader;
                    }, result).Activate();
            });
    }

    private delegate GfdShaderFragment* DGfdShaderFragmentClone(GfdShaderFragment* gfdShaderFragment);

    private delegate GfdShaderFragment* DGfdShaderFragmentSearchFromId(GfdShaderID* pId);

    private delegate GfdShaderFragment* DGfdShaderFragmentCreate(GfdShaderID* pId, byte[] code, int size);

    private delegate GfdShaderFragment* DGfdShaderFragmentCreateFromId(GfdShaderID* pId);
}