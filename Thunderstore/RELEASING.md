# Thunderstore公開手順

1. `Directory.Build.props` のVersionと `CHANGELOG.md` を更新します。
2. `Thunderstore/package.json` のteam、description、website_url、dependenciesを確認します。teamは既存プロジェクトに合わせて `blhsrwznrghfzpr` にしています。website_urlは [GitHubリポジトリ](https://github.com/blhsrwznrghfzpr/SettingsSaveNow) に設定済みです。
3. プロジェクトのルートで `powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1` を実行します。
4. Gale用ZIPをテスト用プロファイルへローカルインポートし、[ゲーム内確認](../TESTING.md)を行います。RML版も別環境で確認します。
5. [Thunderstoreのアップロード画面](https://thunderstore.io/package/create/)で `artifacts/SettingsSaveNow.Thunderstore-<Version>-Release.zip` を選択します。CommunityはResonite、Teamはpackage.jsonに設定したチーム、カテゴリはMods / Dashboard / AI Generatedを指定します。
6. 公開後にGaleのThunderstore一覧から新規導入できることを確認します。ローカル導入版は先に削除して重複を避けてください。

RML版とBepis手動導入版のZIPはGitHub Releases等で別途配布できます。Gale用ZIPはローカル試用向けで、ThunderstoreにはThunderstore用ZIPをアップロードします。

Thunderstore用ZIP:

```text
manifest.json
README.md
CHANGELOG.md
LICENSE
icon.png
plugins/SettingsSaveNow/SettingsSaveNow.dll
plugins/SettingsSaveNow/SettingsSaveNow.pdb
```

Gale用ZIPはDLL/PDBをルートに置き、manifestにauthorを追加します。バージョンと依存関係は共通の入力から生成します。GaleはローカルZIP内のmanifestから依存関係を読み取り、ファイルをプロファイルのBepInEx/plugins配下に配置します。

仕様・実装の参照:

- [Remora.Resonite.Sdk](https://www.nuget.org/packages/Remora.Resonite.Sdk/2.3.4)
- [Thunderstore package format](https://wiki.thunderstore.io/mods/creating-a-package)
- [Resonite packaging guide](https://modding.resonite.net/creating-a-mod/packaging-and-publishing/)
- [Gale local import](https://github.com/Kesomannen/gale/blob/master/src-tauri/src/profile/import/local.rs)
- [Gale loader routing](https://github.com/Kesomannen/gale/blob/master/src-tauri/src/game/mod_loader.rs)

ビルドスクリプトはアップロードを行いません。
