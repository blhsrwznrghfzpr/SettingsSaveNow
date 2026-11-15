using FrooxEngine;
using HarmonyLib;

namespace SettingsSaveNow;

[HarmonyPatch(typeof(RootCategoryView), "OnFeedGenerationFinished")]
internal static class SettingsViewPatch
{
    [HarmonyPostfix]
    private static void Postfix(RootCategoryView __instance)
    {
        // The same view type is also used for unrelated feeds and world objects.
        if (__instance.Feed.Target is not SettingsDataFeed || !__instance.World.IsUserspace())
            return;

        try
        {
            SaveButton.Attach(__instance);
        }
        catch (Exception exception)
        {
            Elements.Core.UniLog.Error($"[SettingsSaveNow] Could not add the save button:\n{exception}");
        }
    }
}
