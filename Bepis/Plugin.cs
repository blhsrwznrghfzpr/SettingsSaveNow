using BepInEx;
using BepInEx.NET.Common;
using BepInExResoniteShim;
using HarmonyLib;

namespace SettingsSaveNow;

[ResonitePlugin(PluginGuid, "SettingsSaveNow", PluginMetadata.VERSION, PluginMetadata.AUTHORS, PluginMetadata.REPOSITORY_URL)]
[BepInDependency(BepInExResoniteShim.PluginMetadata.GUID)]
public sealed class Plugin : BasePlugin
{
    public const string PluginGuid = "dev.blhsrwznrghfzpr.SettingsSaveNow";

    public override void Load()
    {
        var harmony = new Harmony(PluginGuid);
        try
        {
            harmony.PatchAll(typeof(Plugin).Assembly);
        }
        catch
        {
            harmony.UnpatchSelf();
            throw;
        }
        Log.LogInfo("SettingsSaveNow loaded.");
    }
}
