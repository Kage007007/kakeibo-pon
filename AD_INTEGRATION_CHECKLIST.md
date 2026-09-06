# 広告導入チェックリスト

広告を導入する際に必要な作業の完全チェックリストです。
**重要：この順番で作業を進めてください。**

---

## フェーズ1：事前準備

### ✅ AdMobアカウントのセットアップ
- [ ] Google AdMobにアクセス (https://admob.google.com)
- [ ] Googleアカウントでログイン
- [ ] 新しいアプリを登録
  - アプリ名：家計簿ポン
  - プラットフォーム：iOS
  - App Store URL：（リリース後に取得）
- [ ] アプリIDを取得（ca-app-pub-XXXXXXXXXXXXXXXX~AAAAAAAAAA）

### ✅ 広告ユニットの作成
- [ ] バナー広告ユニットを作成
  - 広告ユニット名：「Home Banner」
  - 広告ユニットID取得：ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY
- [ ] （オプション）リワード広告ユニットを作成
  - 広告ユニット名：「Reward Ad」
  - 広告ユニットID取得：ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ

### ✅ ファミリー向け広告プログラムの設定
- [ ] AdMobで「設定」→「アプリ設定」
- [ ] 「子ども向けの設定」を選択
- [ ] 年齢レーティング4+を維持するため、適切な設定を選択

---

## フェーズ2：Flutter実装

### ✅ 依存関係の追加
- [ ] `pubspec.yaml`に追加：
```yaml
dependencies:
  google_mobile_ads: ^5.0.0  # 最新バージョンを確認
```
- [ ] `flutter pub get`を実行

### ✅ iOS設定ファイルの更新

#### Info.plist（ios/Runner/Info.plist）
- [ ] GADApplicationIdentifierを追加：
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~AAAAAAAAAA</string>
```

- [ ] App Tracking Transparencyの説明文を追加：
```xml
<key>NSUserTrackingUsageDescription</key>
<string>よりパーソナライズされた広告を表示するために使用します</string>
```

- [ ] SKAdNetworkItemsを追加（AdMobが提供するリストをコピー）：
```xml
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
  <!-- 他のSKAdNetwork IDも追加（AdMob公式ドキュメント参照） -->
</array>
```

### ✅ コード実装

#### main.dartの初期化
- [ ] `main()`関数でAdMobを初期化：
```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(MyApp());
}
```

#### 広告IDの管理
- [ ] `lib/config/ad_config.dart`を作成：
```dart
class AdConfig {
  static const String appId = 'ca-app-pub-XXXXXXXXXXXXXXXX~AAAAAAAAAA';
  static const String bannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';

  // テスト用ID（開発時のみ使用）
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';
}
```

#### バナー広告の実装
- [ ] メイン画面にバナー広告を追加
- [ ] 広告の読み込みエラー処理を実装
- [ ] 広告の表示位置を調整（ユーザー体験を損なわないように）

### ✅ テスト
- [ ] テスト広告IDで動作確認
- [ ] 実機でApp Tracking Transparencyダイアログが表示されることを確認
- [ ] 広告が正しく表示されることを確認
- [ ] 広告のクリック動作を確認

---

## フェーズ3：ドキュメント更新

### ✅ PRIVACY_POLICY.mdの更新
- [ ] 「第三者サービス」セクションを以下に更新：

```markdown
### 第三者サービスの使用

当アプリは以下の第三者サービスを使用しています：

**Google AdMob**（広告表示）
- 目的：アプリの無料提供を継続するため
- 収集されるデータ：広告識別子（IDFA）、デバイス情報、使用状況データ
- データの用途：パーソナライズされた広告の表示
- プライバシーポリシー：https://policies.google.com/privacy
- オプトアウト方法：iOS設定 > プライバシー > トラッキング

**重要：**
- あなたの収支データ（収入、支出、金額など）は引き続き外部に送信されません
- 広告表示のために使用されるのは、デバイスの広告識別子のみです
- 収支データと広告は完全に分離されています
```

### ✅ APP_STORE_DESCRIPTION.mdの更新（必要に応じて）
- [ ] 「このバージョンの新機能」セクションを確認
- [ ] バージョン番号を更新（1.0.1など）

---

## フェーズ4：App Store Connect設定

### ✅ バージョン情報の準備
- [ ] Xcode でバージョン番号を更新（例：1.0.0 → 1.0.1）
- [ ] ビルド番号を更新（例：1 → 2）

### ✅ プライバシー設定の更新

#### App Store Connectにログイン
- [ ] https://appstoreconnect.apple.com にアクセス
- [ ] マイApp > 家計簿ポン を選択

#### 「Appプライバシー」タブ
- [ ] 「編集」をクリック

#### データタイプの追加

**識別子（Identifiers）**
- [ ] 「デバイスID」を選択
- [ ] 収集目的：
  - ☑ サードパーティ広告
  - ☑ 開発者の広告またはマーケティング
- [ ] 「このデータはユーザーにリンクされていますか？」→ **いいえ**
- [ ] 「このデータを追跡に使用しますか？」→ **はい**

**使用状況データ（Usage Data）**
- [ ] 「製品インタラクション」を選択
- [ ] 収集目的：
  - ☑ サードパーティ広告
  - ☑ 分析
- [ ] 「このデータはユーザーにリンクされていますか？」→ **いいえ**
- [ ] 「このデータを追跡に使用しますか？」→ **はい**

**診断（Diagnostics）**
- [ ] 「クラッシュデータ」を選択（必要に応じて）
- [ ] 収集目的：
  - ☑ App機能
- [ ] 「このデータはユーザーにリンクされていますか？」→ **いいえ**
- [ ] 「このデータを追跡に使用しますか？」→ **いいえ**

#### 追跡に関する質問
- [ ] 「このAppはユーザーやデバイスから収集したデータを使用して、ユーザーを追跡しますか？」
  → **はい**（パーソナライズド広告の場合）
- [ ] 「このAppは、第三者の広告ネットワークを使用して広告を表示しますか？」
  → **はい**

- [ ] 変更を保存

### ✅ 新バージョンの作成
- [ ] 「バージョン」タブ > 「+」ボタン
- [ ] バージョン番号を入力（例：1.0.1）
- [ ] 「このバージョンの新機能」を入力：

```
バージョン 1.0.1

【改善】
• アプリの安定性向上
• 無料提供を継続するため、広告表示を導入しました

引き続き、あなたのプライバシーを大切にしています。
収支データは引き続き端末内にのみ保存され、外部に送信されることはありません。
```

### ✅ ビルドのアップロード
- [ ] Xcodeでアーカイブ作成
- [ ] App Store Connectにアップロード
- [ ] アップロードしたビルドを選択

---

## フェーズ5：リリース前の最終確認

### ✅ 整合性チェック
- [ ] Info.plistの設定 ✓
- [ ] App Store Connectのプライバシー設定 ✓
- [ ] PRIVACY_POLICY.mdの内容 ✓
- [ ] 3つが完全に一致していることを確認

### ✅ 機能テスト
- [ ] TestFlightでベータテスト
- [ ] 広告が正しく表示されることを確認
- [ ] App Tracking Transparencyダイアログの動作確認
- [ ] 既存機能に影響がないことを確認

### ✅ スクリーンショット
- [ ] 必要に応じて新しいスクリーンショットを用意
- [ ] 広告が表示された状態のスクリーンショットも検討

---

## フェーズ6：審査申請

### ✅ 審査に提出
- [ ] App Store Connectで「審査に提出」をクリック
- [ ] 審査ノートに以下を記載（必要に応じて）：

```
バージョン 1.0.1では、アプリの無料提供を継続するため、
Google AdMobを使用した広告表示機能を追加しました。

ユーザーの収支データは引き続きデバイス内にのみ保存され、
外部サーバーに送信されることはありません。

広告表示のために収集されるデータは、広告識別子（IDFA）のみです。
```

### ✅ 審査結果の確認
- [ ] 審査中のステータスを確認
- [ ] リジェクトされた場合は、理由を確認して対応
- [ ] 承認されたら、リリース日を設定

---

## フェーズ7：リリース後

### ✅ モニタリング
- [ ] AdMobダッシュボードで広告表示回数を確認
- [ ] App Store Connectでレビューを確認
- [ ] ユーザーからの問い合わせに対応

### ✅ フィードバック対応
- [ ] ネガティブなレビューがあれば、真摯に対応
- [ ] 広告に関する要望があれば、検討（広告除去の有料オプションなど）

---

## 重要な注意事項

### ⚠️ やってはいけないこと
- ❌ テスト広告IDのまま本番リリース
- ❌ App Store Connect設定とアプリ実装の不一致
- ❌ Info.plistの記述漏れ
- ❌ プライバシーポリシーの更新忘れ
- ❌ ユーザーへの事前告知なし

### ✅ 推奨事項
- ✅ TestFlightで十分にテスト
- ✅ 審査ノートで変更内容を明記
- ✅ リリース後、ユーザーレビューをモニタリング
- ✅ AdMobの収益レポートを定期的に確認

---

## トラブルシューティング

### 審査でリジェクトされた場合

**よくあるリジェクト理由：**
1. プライバシー設定とアプリの動作が不一致
   → App Store Connectの設定を見直し

2. NSUserTrackingUsageDescriptionが不適切
   → より明確な説明文に変更

3. 広告が画面の大部分を占めている
   → 広告の配置を調整

4. 子ども向けアプリで不適切な広告
   → AdMobのファミリー向け設定を確認

### 広告が表示されない場合

**チェックポイント：**
1. テスト広告IDで試す
2. AdMobアカウントの承認待ち（最大24時間）
3. 広告インベントリの不足（時間をおいて再確認）
4. Info.plistの設定ミス

---

## 参考リンク

- [Google AdMob公式ドキュメント](https://developers.google.com/admob/flutter/quick-start)
- [App Store Connect ヘルプ](https://developer.apple.com/help/app-store-connect/)
- [App Tracking Transparency](https://developer.apple.com/documentation/apptrackingtransparency)
- [SKAdNetwork](https://developer.apple.com/documentation/storekit/skadnetwork)

---

**最終更新：2026年1月**
**対象バージョン：1.0.1（広告導入版）**
