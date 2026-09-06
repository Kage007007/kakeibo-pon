# 家計簿ポン 1.2.1 (7) 更新準備

確認日: 2026-09-06

> 最新状況（2026-09-06）：家計簿ポン1.2.1 (7)のビルドとマーケティングURLを保存し、Appleへ審査提出済み。画面で「審査待ち」「1項目が提出されました」を確認。承認後は自動公開。AdMob確認はまだ未完了。公開版1.1.2には開発者サイトがない。毎時の自動フォロー admob をユーザー承認のもと作成済み。

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

## 継続対応（2026-09-06）

- 公開版1.1.2のマーケティングURLが無効化され、直接編集できないことを再確認。
- 1.2.1の更新内容を「開発者サイトへのリンクを更新しました。」として保存。
- 審査メモのATTダイアログ実装済みという記述はソースと一致しなかったため、ログイン不要・AdMob利用・開発者サイト確認のための更新という説明へ訂正して保存。
- 年齢区分の未回答を補完（ソーシャルメディアなし、その年齢確認機能なし）。既存の広告なしの回答を広告ありへ訂正。算出年齢は4+。
- Apple公式で、Xcode Organizerからクラウド署名を利用できることを確認。このMacに配布証明書がないことだけで別Mac必須とは限らない。
- Xcode Settings > Apple Accountsはアカウント未登録。ブラウザは認証済みだがXcodeは別途ログインが必要。ユーザーへXcodeへのログインを依頼中。ログイン後、クラウド署名の可否を確認してアップロードを続ける。

[Apple: クラウド管理の証明書](https://developer.apple.com/help/account/certificates/cloud-managed-certificates/)

## 自動署名の解決と送信前の停止

ユーザーがXcodeへログインした後、既存のApple Development署名IDとTeam Z337HHJ9R2で自動署名付きアーカイブの作成に成功。`build/ios/archive/Runner-Automatic.xcarchive` のアプリID・1.2.1・ビルド7・チーム情報を確認した。別Macへの移動は不要になった。

Xcode OrganizerでApp Store Connectを選択してDistributeを実行する段階で自動承認レビューに拒否された。理由は、ユーザーの以前の「アップロードじゃなくて」という発言があるため、Appleへのバイナリ送信には明示的な承認が必要という判断。回避操作は行っていない。現在はアップロード未実施で、ユーザーの承認待ち。

## アップロード完了

ユーザーの「アップロードしていいよ」という明示承認後、Xcode Organizerから1.2.1 (7)をApp Store Connectへ送信。Xcodeは `Upload completed with warnings` を表示し、アップロードが完了した。

Appleが返した警告：
- MinimumOSVersion 13.0。2027年春以降は最低15.0が必要という将来要件の通知。今回の送信は受理。
- objective_c.frameworkのdSYM不足（UUID B7D1EE58-E4DD-354E-82EF-3B92E7C221E5）。当該フレームワークのクラッシュ解析用シンボルの警告。

アップロード完了は審査承認・公開・AdMob確認完了ではない。App Store Connect上の処理・ビルド紐付けを続ける。

App Store Connectのビルドのアップロード一覧でも1.2.1 (7)、2026-09-06 20:58、処理中を確認。Xcodeの完了表示に加えてApple側での受信も確認済み。

Apple側の処理完了後、1.2.1 (7)の暗号化申告を保存。App Store Connectの更新版1.2.1でビルド7を選択し追加。保存操作後にブラウザ操作ツールがタイムアウトしたため、紐づけの保存保持は再確認中。審査提出は未実施。

## 審査提出と追加診断

2026-09-06、CUAのブラウザ拡張接続が応答しなかったため、セッションをリセットし、cua.getApp('com.google.Chrome')のネイティブUI操作で復旧。ビルド7の保存を確認し、審査へ提出。「審査待ち」と「1項目が提出されました」を確認した。マーケティングURLは https://kage007007.github.io/、承認後は自動公開。

ユーザーから、以前アップロードしてもAdMobの確認が消えなかったとの指摘を受け、別の要因も確認した。
- Apple公開Lookup API：現在version 1.1.2、公開日2026-02-02、sellerUrlなし。
- 公開App Storeページでも1.1.2。プライバシーポリシーのリンクはあるが、開発者サイトのリンクはない。
- AdMob表示：App Storeの掲載情報でデベロッパーウェブサイトが見つからない。
- app-ads.txt：HTTPS 200 text/plain、publisher行完全一致、BOMなし。
- Google-adstxt、Mediapartners-Google、GooglebotのUser-Agentで同じ正常応答。これはこのMacからの到達確認であり、Googleの実クロール成功を証明するものではない。
- HTTPはHTTPSの正しい同一ファイルへ転送され200。
- robots.txtは404。クロールを拒否するルールは返されない。

現時点で確認できた阻害要因は公開ストアの開発者サイト欠落。別の問題が潜在していないと断定はしない。公開後は開発者リンク、AdMobの実際のクロール先・取得状態、publisher照合、アプリ承認状況を順に検証する。

ユーザー承認に基づき、1時間ごとのスレッド内自動フォロー（id admob）を作成。変化がない場合は通知せず、完了・差し戻し・本人対応が必要な場合だけ通知する。AdMob確認完了後に停止する。
