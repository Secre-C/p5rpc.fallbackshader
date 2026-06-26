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