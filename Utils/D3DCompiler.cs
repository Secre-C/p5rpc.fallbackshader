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
            NoBuildPath = true,
            NoWarnings =  false,
        }, false, Logger.DebugLog);

        var shader = compiler.CompileFile(source);
        
        using var byteStream = new MemoryStream();
        using var writer = new BinaryObjectWriter(byteStream, StreamOwnership.Retain, Endianness.Little);
        shader.Write(writer);
        return byteStream.ToArray();
    }

    public static unsafe void Validate(string shaderHashDump, string modDir)
    {
        var lines = File.ReadAllLines(shaderHashDump);

        foreach (var line in lines)
        {
            Logger.DebugLog(line);
            var split = line.Split('_', 2);
            var type = split[0];
            var hash =  split[1];
            
            var pId = GfdShaderID.Parse(hash);
            var macros = gfdShaderDefines.GenerateShaderArgs(&pId);

            var profile = "ps";
            
            if (type == "Pixel")
                profile = "ps";
            else if (type == "Vertex")
                profile = "vs";
            else
                throw new("Invalid Shader Type");

            var shaderSrcDir = Path.Join(modDir, "ShaderSrc");
            var compiledDir = Path.Join(modDir, "compiled");

            try
            {
                var compiled = CompileShader(Path.Join(shaderSrcDir, $"{pId.type}_{profile}.hlsl"), profile + "_5_0", macros,
                    ShaderFlags.OptimizationLevel3);
                
                File.WriteAllBytes(Path.Join(compiledDir, line + ".bin"), compiled);
            }
            catch (Exception e)
            {
                Console.WriteLine($"Failed to Compile {line}: {e}");
            }
        }
    }
}