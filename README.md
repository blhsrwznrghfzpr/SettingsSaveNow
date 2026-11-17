# SettingsSaveNow

Resoniteの設定画面に「保存」ボタンを追加するModです。終了を待たずに、ローカル設定とログイン中のアカウント設定を保存できます。

このModは、[Resonite-Issues #6163](https://github.com/Yellow-Dog-Man/Resonite-Issues/issues/6163) で要望されている、Resoniteを終了せずに設定を手動で保存する機能を追加します。

## 使い方

ダッシュボードの設定画面を開き、カテゴリ一覧の先頭にある **保存** を押します。保存中・完了・失敗をボタンに表示します。日本語UIでは日本語、それ以外では英語で表示します。

Resonite標準の `SettingManagersManager.SaveAllSettings()` を呼び出します。アカウント設定のクラウドへのアップロードはResoniteの通常の同期処理に従い、ボタンの完了表示はアップロード完了を保証しません。未ログイン時はローカル設定のみを保存します。`-NeverSaveSettings` 指定時は保存しません。ワールドやアバター、他のModの設定ファイルを保存する機能ではありません。

## インストール

**BepisLoader版（Gale）**

公開後はGaleでResoniteを選択し、ThunderstoreからSettingsSaveNowをインストールします。公開前は `SettingsSaveNow.Gale-1.0.0-Release.zip` を「Import local mod」で読み込めます。依存するBepisLoaderとBepInExResoniteShimも導入してください。Thunderstoreバックエンドを有効にしておくと、manifestの依存関係をGaleが解決します。

手動導入の場合は `SettingsSaveNow.Bepis-1.0.0-Release.zip` をResoniteのインストール先に展開します（BepisLoaderとBepInExResoniteShim導入済みであること）。

**RML版**

ResoniteModLoader導入済みの環境で `SettingsSaveNow.RML-1.0.0-Release.zip` をResoniteのインストール先に展開するか、DLLを `rml_mods/SettingsSaveNow.dll` に配置します。

同じ環境にはどちらか一方だけを導入してください。

## ビルド

.NET 10 SDKを用意し、プロジェクトのルートで実行します。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

[Remora.Resonite.Sdk 2.3.4](https://www.nuget.org/packages/Remora.Resonite.Sdk/2.3.4) の参照アセンブリを使用します。Resoniteのインストールは不要です。SDKの対象APIはResonite `2026.8.27.1094` です。

`artifacts/` にRML版、Bepis手動導入版、Thunderstore版、Galeローカル導入版を生成します。ゲームへの自動インストールやアップロードは行いません。バージョンは `Directory.Build.props`、公開用情報は `Thunderstore/package.json` で管理します。

## 検証

`build.ps1` は保存の同時実行抑止、成功・例外・キャンセル後の再試行、SDK上のパッチ対象API、配布ZIPの構成を検査します。ゲーム内UIやディスクへの実保存の確認にはResoniteでのテストが必要です。[確認手順](TESTING.md)と[公開手順](Thunderstore/RELEASING.md)を参照してください。

## English

Adds a **Save settings** button at the top of Resonite's settings category list. It invokes the same local/account settings save routine used on exit, with progress feedback and protection against repeated clicks. Cloud uploads follow Resonite's normal synchronization process.

Choose either the BepisLoader or RML build. The Thunderstore archive is intended for publishing; the Gale archive is convenient for local imports before publication.

## Links

- [Source code](https://github.com/blhsrwznrghfzpr/SettingsSaveNow)
- [Issues](https://github.com/blhsrwznrghfzpr/SettingsSaveNow/issues)
