# SettingsSaveNow

Save your Resonite settings without exiting the game.

Open **Dashboard > Settings** and press **Save settings** at the top of the category list. The button shows progress, completion, or failure; press it again to save newer changes or retry a failed save. Japanese interfaces display **保存**.

- Saves local settings and the current account's settings using Resonite's normal save routine.
- Prevents overlapping button-triggered saves, including across multiple settings facets.
- Honors `-NeverSaveSettings`.
- Works without logging in (local settings only).

Account settings are saved locally and queued for Resonite's normal cloud synchronization. A completed save does not mean the cloud upload has finished. This does not save worlds, avatars, or other mods' configuration files.

## Installation

Install with **Gale** or another Thunderstore-compatible mod manager. BepisLoader and BepInExResoniteShim are declared as dependencies.

For a pre-release local test, import the Gale ZIP using **Import local mod** with Thunderstore enabled. Ensure both dependencies are installed.

This package contains the **BepisLoader** version. Install only one version of SettingsSaveNow in a profile; the RML version is distributed separately.

## 日本語

設定画面のカテゴリ一覧の先頭に「保存」ボタンを追加します。終了を待たずに設定を保存でき、保存中・完了・失敗を表示します。クラウドへの反映はResoniteの通常の同期処理に従います。

## Links

- [Source code](https://github.com/blhsrwznrghfzpr/SettingsSaveNow)
- [Issues](https://github.com/blhsrwznrghfzpr/SettingsSaveNow/issues)
