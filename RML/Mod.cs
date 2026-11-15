using HarmonyLib;
using ResoniteModLoader;

namespace SettingsSaveNow;

public sealed class Mod : ResoniteMod
{
    private const string HarmonyId = "dev.blhsrwznrghfzpr.SettingsSaveNow";

    public override string Name => "SettingsSaveNow";
    public override string Author => "blhsrwznrghfzpr";
    public override string Version => typeof(Mod).Assembly.GetName().Version!.ToString(3);
    public override string Link => "https://github.com/blhsrwznrghfzpr/SettingsSaveNow";

    public override void OnEngineInit()
    {
        var harmony = new Harmony(HarmonyId);
        try
        {
            harmony.PatchAll(typeof(Mod).Assembly);
        }
        catch
        {
            harmony.UnpatchAll(HarmonyId);
            throw;
        }
        Msg("SettingsSaveNow loaded.");
    }
}
