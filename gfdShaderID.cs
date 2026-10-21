using System.Globalization;

namespace p5rpc.fallbackshader;

internal struct GfdShaderID
{
    internal ushort type;
    internal short unk02;
    internal uint flag0;
    internal uint flag1;
    internal uint flag2;
    internal uint flag3;
    internal uint texcoordin;
    internal uint texcoordout;

    public string GetHashCode()
    {
        return $"{type}_{flag0:X}_{flag1:X}_{flag2:X}_{flag3:X}_{texcoordin:X}_{texcoordout:X}";
    }

    public override string? ToString()
    {
        return
            $"type -> {type:X}\n" +
            $"flag0 -> 0x{flag0:X8}\n" +
            $"flag1 -> 0x{flag1:X8}\n" +
            $"flag2 -> 0x{flag2:X8}\n" +
            $"flag3 -> 0x{flag3:X8}\n" +
            $"texcoordin -> 0x{texcoordin:X8}\n" +
            $"texcoordout -> 0x{texcoordout:X8}\n";
    }

    public static GfdShaderID Parse(string hash)
    {
        var split = hash.Split('_');

        if (split.Length != 7)
            throw new("invalid hash format");

        return new GfdShaderID
        {
            type = ushort.Parse(split[0], NumberStyles.HexNumber),
            unk02 = 0,
            flag0 = uint.Parse(split[1], NumberStyles.HexNumber),
            flag1 = uint.Parse(split[2], NumberStyles.HexNumber),
            flag2 = uint.Parse(split[3], NumberStyles.HexNumber),
            flag3 = uint.Parse(split[4], NumberStyles.HexNumber),
            texcoordin = uint.Parse(split[5], NumberStyles.HexNumber),
            texcoordout = uint.Parse(split[6], NumberStyles.HexNumber),
        };
    }
}