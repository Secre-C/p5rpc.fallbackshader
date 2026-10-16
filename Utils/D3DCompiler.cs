using Amicitia.IO.Binary;
using Amicitia.IO.Streams;
using HedgeDev.Shaders.HE2.Compiler;
using Vortice.D3DCompiler;
using Vortice.Direct3D;

namespace p5rpc.fallbackshader.Utils;

public static class D3DCompiler
{
    internal static byte[] CompileShader(string source, string profile, ShaderMacro[] macros, ShaderFlags flags)
    {
        var compiler = new ShaderCompiler(new ShaderCompilerArguments
        {
            ShaderProfile = profile,
            CompilerFlags = flags,
            BuildV1 = false,
            EntryPoint = "main",
            ExtraMacros = macros.ToList(),
            NoBuildPath = true
        }, false, Logger.DebugLog);

        var shader = compiler.CompileFile(source);
        
        using var byteStream = new MemoryStream();
        using var writer = new BinaryObjectWriter(byteStream, StreamOwnership.Retain, Endianness.Little);
        shader.Write(writer);
        return byteStream.ToArray();
    }
}