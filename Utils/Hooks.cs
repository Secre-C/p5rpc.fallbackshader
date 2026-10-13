using Reloaded.Hooks.Definitions;

namespace p5rpc.fallbackshader.Utils;

internal struct AsmHookWrapper
{
    internal IAsmHook AsmHook;
    internal IReverseWrapper ReverseWrapper;

    internal AsmHookWrapper(IAsmHook asmHook, IReverseWrapper reverseWrapper)
    {
        AsmHook = asmHook;
        ReverseWrapper = reverseWrapper;
    }
}