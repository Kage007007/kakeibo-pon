# 家計簿ポン 1.2.1 (7) 更新準備

確認日: 2026-09-06

## 今回の目的

AdMobのアプリ所有者確認が進まない原因は、公開済みApp Store掲載情報のマーケティングURLが空欄だったこと。サポートURLだけではGoogleが開発者サイトを参照できない。

- App Store ID: `6757181596`
- Bundle ID: `com.kageyamarinkyuu.kakeiboppon`
- App Store Connectで1.2.1の下書き作成済み。
- マーケティングURL `https://kage007007.github.io/` を保存し、再読込後も保持を確認。
- 同サイトの `/app-ads.txt` はHTTP 200、text/plainで次の正しい行を返す。

```text
google.com, pub-5520164831450548, DIRECT, f08c47fec0942fa0
```

ソースは2026-09-06 20:04 JSTにGitHubへ到着。元コミットは `cd486cb60206031b554584f5bf2e8fa2036cd907`（1.2.0+6）。

## 更新内容

- バージョンを `1.2.1+7` に変更。
- Debug/ProfileではGoogleのテスト広告を自動選択。Releaseは既存の本番広告IDを使用。
- Releaseでも `--dart-define=USE_TEST_ADS=true` でテスト広告を選択できる。
- 既存の広告枠ID、依存パッケージ、データ保存形式、署名設定は維持。

## 検証済み

Flutter **3.38.4** / Dart **3.10.3**、Xcode 26.5、iOS 26.5のiPhone 17シミュレータで確認。

- `flutter pub get`: 成功、pubspec.lockの差分なし。
- `flutter test --no-pub`: 既存スモークテスト1件成功。
- `flutter build ios --simulator --debug --no-pub`: 成功。
- 実操作: 食費100円を入力・保存し、分析と取引履歴への反映を確認。アプリ再起動後も保持。
- テスト広告: Medium Rectangle、Rewarded、Interstitialの読み込み成功。今回は全画面広告の視聴完了までは未検証。
- `flutter build ipa --release --no-pub --no-codesign`: アーカイブ成功。1.2.1 / 7 / iOS 13.0 / Bundle IDの検証成功。署名なしのためIPAは生成されない。
- `flutter analyze --no-pub`: エラー0、警告10、info 366。既存の未使用コード・非推奨API等が残っており、解析全体の終了コードは非ゼロ。

通知の許可をしないシミュレータ環境では通知サービスの初期化が5秒でタイムアウトする既存挙動があるが、その後アプリは起動する。ビルドではアイコン・起動画面のプレースホルダー警告が出る。1024pxのストア用画像と180px画像は家計簿ポンの既存ロゴと確認済みだが、全サイズの資産監査は未完了。

Flutter 3.47.2ではgoogle_mobile_adsとwebview_flutter_wkwebviewのCocoaPods/SPM混在でビルドが失敗したため、今回は元の3.38.4を使用する。依存関係の一括アップグレードは不要。

## 現在のブロッカー

このMacで通常の `flutter build ipa --release --no-pub` を実行すると、配布プロファイル `Kakeibo Pon Distribution`（Team `Z337HHJ9R2`）が見つからず署名に失敗する。コード署名ID一覧ではApple Developmentのみ確認でき、配布用の署名IDはない。

証明書の作成・移動・秘密鍵の取り出し・署名設定変更は行っていない。アップロード・審査提出・公開・AdMob所有者確認も未完了。

## 配布用署名のある元のMacで続ける手順

未保存の変更がある場合は保持したうえで、この更新ブランチ `codex/admob-store-link-1.2.1` を取得し、Flutter 3.38.4で作業する。

```sh
flutter --version
flutter pub get
flutter test --no-pub
flutter build ipa --release --no-pub
```

1. XcodeでTeam `Z337HHJ9R2`、プロファイル `Kakeibo Pon Distribution` を確認して署名する。
2. アイコン・起動画面の警告を確認し、既存の製品画像が各対象サイズに入っていることを確認する。
3. Xcode OrganizerまたはTransporterから1.2.1 (7)をApp Store Connectにアップロードする。既に7が使われていれば番号を重複させず新しい番号にする。
4. 処理完了後、作成済み1.2.1下書きへビルドを選択。マーケティングURLが上記の値であることを確認する。
5. 審査提出に必要な更新内容、輸出コンプライアンス、年齢区分等を実際のアプリ・事業情報に従って確認する。今回の検証は既存アプリ全体のプライバシー監査を完了した意味ではない。
6. 更新版の公開後、App Storeの開発者サイトリンクを確認し、AdMobの家計簿ポンで「アップデートを確認」を実行する。反映には時間がかかる場合がある。

## 参考

- [Google: iOSの開発者サイトはマーケティングURLに設定](https://support.google.com/admob/answer/9363762?hl=en)
- [Google: app-ads.txtの問題を解決](https://support.google.com/admob/answer/9776740?hl=ja)

旧 `RELEASE_GUIDE.md` は初期作成時の説明。今回の更新では新しいAdMobアカウントや広告枠の作成、広告IDの置換、`useTestAds`の手動固定は不要。
