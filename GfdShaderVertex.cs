using p5rpc.fallbackshader.Utils;
using Reloaded.Hooks.Definitions;
using Vortice.D3DCompiler;
using static p5rpc.fallbackshader.FallbackShader;

namespace p5rpc.fallbackshader;

internal unsafe struct GfdShaderVertex
{
    internal ushort flags;
    internal ushort unk2;
    internal GfdShaderID id;
    internal void* device;
    internal int reference;
    internal GfdShaderVertex* prev;
    internal GfdShaderVertex* next;
}

internal unsafe class GfdShaderVertexFallback
{
    private DFUN_14021e630 FUN_14021e630;
    private DGfdAtomicIncrement _gfdAtomicIncrement;
    private DGfdShaderVertexCreate _gfdShaderVertexCreate;
    private IHook<DGfdShaderVertexCreateFromId> _gfdShaderVertexCreateFromIdHook;
    private DGfdShaderVertexSearchFromId _gfdShaderVertexSearchFromId;

    internal GfdShaderVertexFallback()
    {
        Scanner.SigScan(
            "48 89 5C 24 ?? 48 89 6C 24 ?? 48 89 74 24 ?? 57 41 54 41 55 41 56 41 57 48 83 EC 50 8B 41",
            "gfdVertexShaderSearchFromID", result => // 0x14021e1a0
            {
                _gfdShaderVertexSearchFromId =
                    hooks.CreateWrapper<DGfdShaderVertexSearchFromId>(result, out var address);
            });

        Scanner.SigScan(
            "48 89 5C 24 ?? 48 89 6C 24 ?? 48 89 74 24 ?? 57 48 83 EC 20 41 8B F0 48 8B EA 48 8B F9 E8 ?? ?? ?? ?? 48 8B D8 48 85 C0 75",
            "gfdShaderVertexCreate", result => // 0x14021de30
            {
                _gfdShaderVertexCreate = hooks.CreateWrapper<DGfdShaderVertexCreate>(result, out var address);
            });

        Scanner.SigScan(
            "B8 01 00 00 00 F0 0F C1 01 FF C0",
            "gfdAtomicIncrement", result => // 0x1401d7230
            {
                _gfdAtomicIncrement = hooks.CreateWrapper<DGfdAtomicIncrement>(result, out var address);
            });

        Scanner.SigScan(
            "48 89 5C 24 ?? 57 48 83 EC 20 48 8B D9 8B FA 48 8D 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? 48 8D 4B ?? E8 ?? ?? ?? ?? 85 C0 0F 85 ?? ?? ?? ?? 48 8B 4B",
            "FUN_14021e630", result => // 0x14021e630
            {
                FUN_14021e630 = hooks.CreateWrapper<DFUN_14021e630>(result, out var address);
            });

        Scanner.SigScan("48 89 5C 24 ?? 57 48 83 EC 20 48 8B F9 E8 ?? ?? ?? ?? 48 8B D8 48 85 C0 75",
            "gfdShaderVertexCreateFromID", result => // 0x14021dfe0 
            {
                _gfdShaderVertexCreateFromIdHook = hooks.CreateHook<DGfdShaderVertexCreateFromId>(
                    pId =>
                    {
                        var foundShader = _gfdShaderVertexSearchFromId(pId);
                        while (true)
                        {
                            if (foundShader != (GfdShaderVertex*)0x0)
                            {
                                _gfdAtomicIncrement(&foundShader->reference);
                                var uVar2 = *(uint*)((nint)_gfdGlobal + 0x2e08);
                                FUN_14021e630(foundShader, uVar2);
                                return foundShader;
                            }

                            if (_gfdGlobal->Field_0x2348 == 0) break;
                            _fun140193460(8000);
                            foundShader = _gfdShaderVertexSearchFromId(pId);
                        }

                        GfdShaderVertex* shader = null;

                        var vShaderSrc = Path.Join(modDir, "ShaderSrc", pId->type + "_vs.hlsl");
                        var shaderFlags = new ShaderFlags();
                        shaderFlags |= ShaderFlags.OptimizationLevel3;

                        var macros = gfdShaderDefines.GenerateShaderArgs(pId);

                        try
                        {
                            var vCode = D3DCompiler.CompileShader(vShaderSrc, "vs_5_0", macros, shaderFlags, config.Debug);
                            if (config.Output)
                                File.WriteAllBytes(Path.Join(modDir, "compiled", "Vertex_" + pId->GetHashCode() + ".bin"), vCode);
                            Logger.DebugLog("Dir: " + vShaderSrc);
                            Logger.DebugLog("Length: " + vCode.Length);
                            shader = _gfdShaderVertexCreate(pId, vCode, vCode.Length);
                            return shader;
                        }
                        catch (Exception e)
                        {
                            Logger.Log($"Failed to compile Vertex shader for {pId->GetHashCode()}: {e.Message}");
                            return null;
                        }
                    }, result).Activate();
            });
    }

    private delegate GfdShaderVertex* DGfdShaderVertexSearchFromId(GfdShaderID* pId);

    private delegate GfdShaderVertex* DGfdShaderVertexCreate(GfdShaderID* pId, byte[] code, int size);

    private delegate int DGfdAtomicIncrement(void* param_1);

    private delegate int DFUN_14021e630(GfdShaderVertex* param_1, uint param_2);

    private delegate GfdShaderVertex* DGfdShaderVertexCreateFromId(GfdShaderID* pId);
}