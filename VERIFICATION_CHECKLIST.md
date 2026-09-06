# 広告実装 検証チェックリスト

## Phase 1-2: 基盤構築の検証

### ✅ 検証1: ビルド成功確認
- [ ] `flutter analyze`でエラーなし
- [ ] `flutter build ios`でビルド成功
- [ ] Info.plistにAdMob設定が正しく追加されている
- [ ] pubspec.yamlにgoogle_mobile_ads追加確認

### ✅ 検証2: AdService初期化確認
- [ ] アプリ起動時にログ確認
  - `MobileAds initialized successfully`
  - `AdService initialized successfully`
- [ ] 初期化失敗時もアプリが続行すること
- [ ] SharedPreferencesにデータが保存されること

## Phase 3: インタースティシャル広告の検証

### 検証3: 頻度制御の動作確認

#### 3-1. N回に1回の制御（デフォルト: 5回に1回）
- [ ] トランザクションを1回保存 → 広告表示なし
- [ ] トランザクションを2回保存 → 広告表示なし
- [ ] トランザクションを3回保存 → 広告表示なし
- [ ] トランザクションを4回保存 → 広告表示なし
- [ ] トランザクションを5回保存 → **広告表示あり**
- [ ] トランザクションを6回保存 → 広告表示なし
- [ ] トランザクションを10回保存 → **広告表示あり**

**確認方法**:
```dart
// デバッグログで確認
debugPrint('📊 Interstitial shown (daily: X/10)');
```

#### 3-2. 時間間隔制御（デフォルト: 10分）
- [ ] 5回保存後に広告表示
- [ ] 直後に5回保存 → 広告表示なし（10分経過していない）
- [ ] ログ確認: `⏱️ Too soon since last ad (Xmin < 10min)`
- [ ] 10分後に5回保存 → **広告表示あり**

**確認方法（テスト時短）**:
```dart
// ad_config.dart の minimumIntervalMinutes を一時的に0に変更
minimumIntervalMinutes: 0,  // テスト用
```

#### 3-3. 日次上限制御（デフォルト: 10回/日）
- [ ] 1日に10回広告表示成功
- [ ] 11回目の試行 → 広告表示なし
- [ ] ログ確認: `🚫 Daily limit reached (10/10)`
- [ ] 翌日（日付変更後）→ カウンターリセット
- [ ] ログ確認: `🔄 Daily ad counter reset`

#### 3-4. アニメーション非干渉確認
- [ ] トランザクション保存時のフェードアウトアニメーション（400ms）が正常動作
- [ ] アニメーション完了後に広告が表示される
- [ ] 広告表示中もアプリが固まらない
- [ ] 広告閉じた後に「保存しました」SnackBarが表示される

**確認ポイント**:
```
タイムライン:
0ms: 保存開始
0-400ms: フェードアウトアニメーション
400ms: 広告表示判定
400ms-: 広告表示（別レイヤー）
広告終了: SnackBar表示
```

## Phase 4: バナー広告の検証

### 検証4: バナー広告表示確認

#### 4-1. 基本表示
- [ ] AnalysisScreenにバナー広告が表示される
- [ ] MonthComparisonChart（対前月比較グラフ）の直下に配置
- [ ] 広告サイズ: 320x50
- [ ] 上下マージン: 16px

#### 4-2. レスポンシブ対応
- [ ] iPhone SE (375px) で正常表示
- [ ] iPhone 13 (390px) で正常表示
- [ ] iPhone 13 Pro Max (428px) で正常表示
- [ ] 画面回転（横向き）でレイアウト崩れなし

#### 4-3. エラーハンドリング
- [ ] 広告ロード失敗時に空のスペースが表示される（SizedBox.shrink）
- [ ] ログ確認: `❌ Banner ad failed to load: ...`
- [ ] 30秒後に自動再試行
- [ ] アプリは正常動作を継続

#### 4-4. ライフサイクル管理
- [ ] AnalysisScreenから離れてもメモリリークなし
- [ ] タブ切り替え時にdisposeが呼ばれる
- [ ] AnalysisScreenに戻った時に広告が再表示される

## Phase 5（今後）: ネイティブ広告の検証

### 検証5: ネイティブ広告統合確認
- [ ] サマリー行に広告が自然に統合される
- [ ] デザインが既存カードと統一されている
- [ ] 4つのテーマすべてで適切に表示される
- [ ] 高さ120ptで固定表示

## Phase 6（今後）: リワード広告の検証

### 検証6: リワード広告機能確認
- [ ] SettingsScreenに「開発者を応援」ボタン表示
- [ ] ボタンタップでリワード広告表示
- [ ] 広告視聴完了で感謝メッセージ表示
- [ ] 広告スキップ時も正常動作

## 総合検証

### 検証7: パフォーマンス確認
- [ ] アプリ起動時間: 3秒以内
- [ ] メモリ使用量: 広告なし時と比較して+50MB以内
- [ ] InputScreen保存速度: 広告なし時と同等（1秒以内）
- [ ] AnalysisScreenスクロール: 60FPS維持

### 検証8: エラーケース確認
- [ ] 機内モード時: 広告ロード失敗、アプリ正常動作
- [ ] ネットワーク遅延時: タイムアウト後も正常動作
- [ ] 広告在庫なし: エラーログ表示、アプリ正常動作
- [ ] AdService初期化失敗: アプリ起動成功、広告機能のみ無効

### 検証9: ユーザー体験確認
- [ ] 広告が操作を妨げない
- [ ] 誤タップによる広告表示なし
- [ ] 広告表示頻度が適切（うざくない）
- [ ] 保存速度が損なわれない

## デバッグ用コマンド

### カウンターリセット（テスト時）
```dart
// SettingsScreenに一時的に追加
ElevatedButton(
  onPressed: () async {
    await AdService().resetAllCounters();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('広告カウンターをリセットしました')),
    );
  },
  child: const Text('広告カウンターリセット（デバッグ用）'),
)
```

### 統計情報表示
```dart
// デバッグコンソールで確認
print(AdService().getStats());
```

### 頻度を上げてテスト
```dart
// ad_config.dart を一時的に変更
static const AdFrequencyConfig inputScreenInterstitial = AdFrequencyConfig(
  showEveryNTimes: 2,           // 2回に1回に変更
  minimumIntervalMinutes: 0,    // 間隔なしに変更
  dailyLimit: 100,              // 実質無制限に変更
);
```

## ログ確認項目

### 正常時のログ
```
Starting service initialization...
MobileAds initialized successfully
AdService initialized successfully
✅ Interstitial ad loaded successfully
✅ Banner ad loaded successfully
📊 Interstitial shown (daily: 1/10)
```

### エラー時のログ
```
❌ Interstitial ad failed to load: [エラーメッセージ]
⏱️ Too soon since last ad (5min < 10min)
🚫 Daily limit reached (10/10)
⚠️ Interstitial ad not ready, skipping...
```

## 本番リリース前の最終確認

### チェックリスト
- [ ] ad_config.dart の `useTestAds = false` に変更
- [ ] Info.plist の本番App IDに変更
- [ ] 本番広告IDをad_config.dartに設定
- [ ] TestFlightでベータテスト実施
- [ ] 実機で広告表示確認（3台以上）
- [ ] AdMobダッシュボードで収益確認
- [ ] アプリストアのプライバシーポリシー更新
- [ ] App Store Connectの広告ID設定

## トラブルシューティング

### 広告が表示されない場合
1. ログで初期化成功を確認
2. 広告ユニットIDが正しいか確認
3. Info.plistのApp IDが正しいか確認
4. ネットワーク接続を確認
5. テスト広告IDで試す
6. AdMobダッシュボードでアプリ承認状態を確認

### 頻度制御が動作しない場合
1. SharedPreferencesにデータが保存されているか確認
2. カウンターをリセットして再テスト
3. ログで条件チェック結果を確認
4. ad_config.dartの設定値を確認

### クラッシュする場合
1. main.dartの初期化順序を確認
2. disposeメソッドが正しく実装されているか確認
3. mounted確認が適切に行われているか確認
4. スタックトレースを確認
