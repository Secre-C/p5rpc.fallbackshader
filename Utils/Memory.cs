using System.Diagnostics;

namespace p5rpc.fallbackshader.Utils;

internal static class Memory
{
    internal static readonly long baseAddress = Process.GetCurrentProcess().MainModule.BaseAddress.ToInt64();
    internal static readonly string PushCallerRegisters = "push rcx\npush rdx\npush r8\npush r9\npush r10\npush r11";
    internal static readonly string PopCallerRegisters = "pop r11\npop r10\npop r9\npop r8\npop rdx\npop rcx";

    internal static unsafe nint GetAddressFromGlobalRef(nint instructionAdr, byte length, string name = "")
    {
        var opd = *(int*)(instructionAdr + length - 4);
        var result = instructionAdr + opd + length;

        if (name == string.Empty)
            Logger.DebugLog($"Found Global ref at 0x{result:X} from 0x{instructionAdr:X}");
        else
            Logger.DebugLog($"Found Global ref {name} at 0x{result:X} from 0x{instructionAdr:X}");

        return result;
    }
}