# 本番リリースガイド

家計簿ポンを本番環境にリリースする手順書です。

## ステップ1: AdMobアカウント設定

### 1-1. AdMobアカウント作成
1. https://admob.google.com/ にアクセス
2. Googleアカウントでログイン
3. 新しいAdMobアカウントを作成

### 1-2. アプリを登録
1. AdMobダッシュボードで「アプリ」→「アプリを追加」
2. プラットフォーム: **iOS**
3. アプリ名: **家計簿ポン**
4. App Store ID: （App Store公開後に入力、未公開なら後回しOK）

### 1-3. 広告ユニットを作成

以下の2つの広告ユニットを作成します：

#### A. バナー広告（Medium Rectangle）
- 広告フォーマット: **バナー**
- 広告ユニット名: **AnalysisScreen_MediumRectangle**
- サイズ: **Medium Rectangle (300x250)**
- 作成後、**広告ユニットID**をコピー（`ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY`形式）

#### B. インタースティシャル広告
- 広告フォーマット: **インタースティシャル**
- 広告ユニット名: **DetailNavigation_Interstitial**
- 作成後、**広告ユニットID**をコピー

### 1-4. App IDを取得
- AdMobダッシュボードで「アプリ」→作成したアプリを選択
- **App ID**をコピー（`ca-app-pub-XXXXXXXXXXXXXXXX~ZZZZZZZZZZ`形式）

---

## ステップ2: 本番広告IDを設定

### 2-1. lib/config/ad_config.dart を編集

```dart
// =========================================
// 1. AdMob App ID & Ad Unit ID
// =========================================

// iOS App ID（本番用）
static const String _iosAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~ZZZZZZZZZZ'; // ← ステップ1-4でコピーしたApp ID

// 本番広告ユニットID
static const String _iosBannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY'; // ← Medium Rectangle ID
static const String _iosInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY'; // ← Interstitial ID

// =========================================
// 2. 開発/本番モード切り替え
// =========================================

/// ⚠️ 本番リリース前に必ずfalseに変更！
static const bool useTestAds = false; // ← true から false に変更
```

### 2-2. ios/Runner/Info.plist を編集

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~ZZZZZZZZZZ</string> <!-- ← ステップ1-4のApp IDに変更 -->
```

---

## ステップ3: App Tracking Transparency (ATT) 確認

### 3-1. Info.plistの設定確認

`ios/Runner/Info.plist`に以下が含まれていることを確認：

```xml
<key>NSUserTrackingUsageDescription</key>
<string>このアプリは、あなたに関連性の高い広告を表示するために、他社のアプリやWebサイトを横断してあなたのデータを追跡します。</string>
```

✅ **既に設定済み**

### 3-2. 初回起動時の動作確認
- アプリ初回起動時に許可ダイアログが表示される
- ユーザーが「許可」を選ぶと、パーソナライズ広告が配信される

---

## ステップ4: プライバシーポリシー

### 4-1. 必須記載事項

App Store審査に通過するため、以下を記載したプライバシーポリシーが必要です：

```
【広告配信について】
当アプリは、広告配信のためにGoogle AdMobを使用しています。
AdMobは、ユーザーの行動情報を収集し、パーソナライズ広告を表示する場合があります。

詳細は以下のプライバシーポリシーをご確認ください：
https://policies.google.com/technologies/ads
```

### 4-2. プライバシーポリシーの配置
- Webサイトに公開（例: https://yourwebsite.com/privacy-policy）
- App Store Connectの「プライバシーポリシーURL」に入力

---

## ステップ5: App Store Connect設定

### 5-1. 広告IDの使用を申告
App Store Connectで以下を設定：

1. 「App情報」→「広告識別子（IDFA）」
2. ✅ 「はい、このアプリは広告識別子（IDFA）を使用します」
3. 使用目的を選択：
   - ✅ このアプリ内で広告を配信する
   - ✅ アプリケーション内でのアクションをアトリビュートする

---

## ステップ6: リリースビルド

### 6-1. ビルド前の最終確認

```bash
# ad_config.dartの確認
grep "useTestAds" lib/config/ad_config.dart
# → "static const bool useTestAds = false;" が表示されればOK

# Info.plistの確認
grep "GADApplicationIdentifier" ios/Runner/Info.plist
# → 本番App IDが設定されていることを確認
```

### 6-2. リリースビルド実行

```bash
# クリーンビルド
flutter clean
flutter pub get

# iOSリリースビルド
flutter build ios --release

# または Xcodeでアーカイブ
open ios/Runner.xcworkspace
# Product → Archive
```

---

## ステップ7: TestFlightでベータテスト

### 7-1. TestFlightにアップロード
1. Xcodeでアーカイブ
2. Organizerから「Distribute App」
3. TestFlightを選択してアップロード

### 7-2. ベータテスターで確認
- 広告が正しく表示されるか
- 10回遷移で広告が出るか
- クラッシュしないか
- 広告タップ後の動作

---

## ステップ8: App Store審査提出

### 8-1. 審査前チェックリスト
- [ ] `useTestAds = false` に設定
- [ ] 本番広告IDを設定
- [ ] Info.plistに本番App ID設定
- [ ] プライバシーポリシーURL設定
- [ ] IDFA使用目的を申告
- [ ] TestFlightでテスト完了
- [ ] スクリーンショット準備
- [ ] アプリ説明文作成

### 8-2. 審査提出
App Store Connectで「審査に提出」をクリック

---

## トラブルシューティング

### 本番広告が表示されない場合

1. **AdMobの審査待ち**
   - 新規アプリは広告配信まで数時間〜数日かかる場合があります
   - AdMobダッシュボードで「アプリのステータス」を確認

2. **広告リクエスト数が少ない**
   - 初期は広告在庫が少ない可能性があります
   - 数日間運用して様子を見てください

3. **地域制限**
   - 一部の地域では広告配信されない場合があります

4. **テスト広告IDのまま**
   - `useTestAds = false` になっているか再確認

### ログで確認する方法

```bash
# Xcodeで実機ログを確認
flutter run --release

# 以下のログが出ればOK
# flutter: ✅ AdService initialized successfully
# flutter: ✅ MediumRectangle ad loaded successfully
# flutter: ✅ Interstitial ad loaded successfully
```

---

## 広告収益の確認

### AdMobダッシュボード
- https://admob.google.com/
- 「ホーム」で収益グラフを確認
- 「レポート」で詳細分析

### 支払い設定
1. AdMobダッシュボード → 「お支払い」
2. 銀行口座情報を登録
3. 最低支払額: ¥8,000
4. 支払いサイクル: 翌月21日頃

---

## 現在の広告設定まとめ

### 実装済み広告
1. **Medium Rectangle (300x250)**
   - 場所: 分析画面のサマリーカード下
   - 表示: 常時
   - 予想eCPM: $1-2

2. **インタースティシャル（全画面）**
   - 場所: 詳細画面遷移時（収支推移、カテゴリ詳細）
   - 頻度: 10回に1回、5分間隔、1日10回まで
   - 予想eCPM: $4-5

### 予想収益
- 1,000 DAU想定: $3-6/日
- 10,000 DAU想定: $30-60/日

---

## サポート

問題が発生した場合:
1. `VERIFICATION_CHECKLIST.md` を参照
2. AdMobヘルプセンター: https://support.google.com/admob/
3. Flutterドキュメント: https://pub.dev/packages/google_mobile_ads

---

**最終更新**: 2026-01-13
