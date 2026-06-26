using System.Runtime.InteropServices;

namespace p5rpc.fallbackshader;

[StructLayout(LayoutKind.Explicit)]
internal unsafe struct gfdGlobalGraphics
{
    [FieldOffset(0xA38)]
    internal uint shaderMutex;
    
    [FieldOffset(0x1b20)]
    internal GfdShaderFragment* shaderFragment;

    [FieldOffset(0x2348)] 
    internal uint Field_0x2348;
}