using Elements.Core;
using FrooxEngine;
using FrooxEngine.UIX;

namespace SettingsSaveNow;

internal static class SaveButton
{
    private const string SlotName = "SettingsSaveNow.SaveButton";
    private static readonly SaveOperation Operation = new();
    private static readonly List<WeakReference<Button>> Buttons = new();
    private static SaveStatus _status;

    private enum SaveStatus { Ready, Saving, Completed, Failed, Disabled, NotReady }

    internal static void Attach(RootCategoryView view)
    {
        var container = view.CategoryManager.ContainerRoot.Target;
        if (container == null)
            return;

        // Category regeneration destroys its children. Recreate only when needed.
        var existing = container.FindChild(SlotName);
        if (existing != null)
            return;

        var ui = new UIBuilder(container);
        RadiantUI_Constants.SetupBaseStyle(ui);
        var button = ui.Button((LocaleString)Label(_status));
        button.Slot.Name = SlotName;
        button.Slot.PersistentSelf = false;
        button.Slot.OrderOffset = long.MinValue;
        var layout = button.Slot.GetComponent<LayoutElement>() ?? button.Slot.AttachComponent<LayoutElement>();
        layout.MinHeight.Value = 40f;
        button.LocalPressed += OnPressed;
        Buttons.Add(new WeakReference<Button>(button));
        UpdateButtons(_status);
    }

    private static void OnPressed(IButton button, ButtonEventData eventData)
    {
        if (Operation.IsRunning)
            return;

        var world = button.World;
        if (!world.IsUserspace())
            return;

        var manager = world.GetGloballyRegisteredComponent<SettingManagersManager>();
        if (manager == null || manager.LocalSettings.Target == null)
        {
            UpdateButtons(SaveStatus.NotReady);
            return;
        }
        if (SettingManagersManager.NeverSave)
        {
            UpdateButtons(SaveStatus.Disabled);
            return;
        }

        // Bind the task to the settings manager, not the view: changing categories
        // or closing the dashboard must not cancel a save already in progress.
        _ = manager.StartTask(async () =>
        {
            try
            {
                var ran = await Operation.TryRunAsync(async () =>
                {
                    UpdateButtons(SaveStatus.Saving);
                    // Let the text field lose focus and commit its latest edit first.
                    await new Updates(1);
                    await manager.SaveAllSettings();
                    await default(ToWorld);
                });
                if (ran)
                {
                    UpdateButtons(SaveStatus.Completed);
                    UniLog.Log("[SettingsSaveNow] Settings save completed; cloud synchronization is handled by Resonite.");
                }
            }
            catch (Exception exception)
            {
                UniLog.Error($"[SettingsSaveNow] Settings save failed:\n{exception}");
                await default(ToWorld);
                UpdateButtons(SaveStatus.Failed);
            }
        });
    }

    private static void UpdateButtons(SaveStatus status)
    {
        _status = status;
        for (var i = Buttons.Count - 1; i >= 0; i--)
        {
            if (!Buttons[i].TryGetTarget(out var button) || button.IsRemoved)
            {
                Buttons.RemoveAt(i);
                continue;
            }

            button.Enabled = status != SaveStatus.Saving;
            var text = button.Slot.GetComponentInChildren<Text>();
            if (text != null)
                text.Content.Value = Label(status);
        }
    }

    private static string Label(SaveStatus status)
    {
        var locale = Settings.GetActiveSetting<LocaleSettings>()?.ActiveLocaleCode ?? LocaleSettings.SystemLocale;
        var japanese = locale?.StartsWith("ja", StringComparison.OrdinalIgnoreCase) == true;
        return (status, japanese) switch
        {
            (SaveStatus.Saving, true) => "保存中…",
            (SaveStatus.Completed, true) => "保存完了（再保存）",
            (SaveStatus.Failed, true) => "保存失敗（再試行）",
            (SaveStatus.Disabled, true) => "保存は無効です",
            (SaveStatus.NotReady, true) => "設定の読込待ち",
            (_, true) => "保存",
            (SaveStatus.Saving, false) => "Saving...",
            (SaveStatus.Completed, false) => "Saved (save again)",
            (SaveStatus.Failed, false) => "Failed (retry)",
            (SaveStatus.Disabled, false) => "Saving disabled",
            (SaveStatus.NotReady, false) => "Settings not ready",
            _ => "Save settings"
        };
    }
}
