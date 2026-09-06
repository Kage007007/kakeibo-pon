import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_settings.dart';
import '../services/storage_service.dart';
import '../main.dart' show currentTabIndex;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final StorageService _storage = StorageService();

  static const String _settingsKey = 'notification_settings';
  static const String _lastInputDateKey = 'last_input_date';

  final List<String> _habitMessages = [
    'タップして3秒で入力！習慣化で家計の悩みが消えていきます',
    'タップして3秒で入力！続けるほど未来が明るくなります',
    'タップして3秒で入力！小さな習慣が未来を変えます',
    'タップして3秒で入力！毎日の積み重ねが成果になります',
    'タップして3秒で入力！習慣化があなたの人生を変えます',
    'タップして3秒で入力！続けるほどお金が貯まります',
    'タップして3秒で入力！習慣化で確実に資産が増えていきます',
    'タップして3秒で入力！続けるほど家計が楽になります',
    'タップして3秒で入力！今日も一歩前進しましょう',
    'タップして3秒で入力！3秒の習慣が豊かな未来を作ります',
  ];

  static const String _churnMessage =
      'タップして3秒で入力！お久しぶりです。溜まった分はスキップして、今日から再開しませんか？';

  Future<void> init() async {
    // タイムゾーンデータを初期化
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      iOS: initializationSettingsIOS,
      android: initializationSettingsAndroid,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // アプリ起動時に保存された設定を読み込んで通知を再スケジュール
    await _restoreNotifications();
  }

  Future<void> _restoreNotifications() async {
    try {
      final settings = await getSettings();

      // マスタースイッチがONの場合のみ通知を復元
      if (settings.notificationEnabled) {
        if (settings.habitNotificationEnabled) {
          await scheduleHabitNotification(
            time: settings.notificationTime,
            onlyWhenNoInput: settings.condition == NotificationCondition.onlyWhenNoInput,
          );
        }
        if (settings.churnNotificationEnabled) {
          await scheduleChurnNotification();
        }
        debugPrint('Notifications restored successfully');
      } else {
        debugPrint('Notifications are disabled, skipping restore');
      }
    } catch (e) {
      debugPrint('Error restoring notifications: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        // Android 13以降の通知権限リクエスト
        final result = await androidImplementation.requestNotificationsPermission();
        return result ?? false;
      }
      return true; // Android 12以前は自動的に許可
    }
    return false;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // ディープリンク処理: 通知タップで入力画面に遷移
    // main.dartで定義されたcurrentTabIndexを使用
    // 入力画面はインデックス1
    try {
      currentTabIndex.value = 1;
      debugPrint('Notification tapped - navigating to input screen');
    } catch (e) {
      debugPrint('Error navigating to input screen: $e');
    }
  }

  Future<NotificationSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // 設定が保存されているかチェック
      if (!prefs.containsKey('notificationEnabled')) {
        return NotificationSettings.defaultSettings();
      }

      final Map<String, dynamic> json = {
        'notificationEnabled': prefs.getBool('notificationEnabled') ?? false,
        'habitNotificationEnabled': prefs.getBool('habitNotificationEnabled') ?? false,
        'notificationTimeHour': prefs.getInt('notificationTimeHour') ?? 21,
        'notificationTimeMinute': prefs.getInt('notificationTimeMinute') ?? 0,
        'condition': prefs.getInt('condition') ?? 0,
        'churnNotificationEnabled': prefs.getBool('churnNotificationEnabled') ?? true,
      };
      return NotificationSettings.fromJson(json);
    } catch (e) {
      return NotificationSettings.defaultSettings();
    }
  }

  Future<void> saveSettings(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final json = settings.toJson();
    await prefs.setBool('notificationEnabled', json['notificationEnabled']);
    await prefs.setBool('habitNotificationEnabled', json['habitNotificationEnabled']);
    await prefs.setInt('notificationTimeHour', json['notificationTimeHour']);
    await prefs.setInt('notificationTimeMinute', json['notificationTimeMinute']);
    await prefs.setInt('condition', json['condition']);
    await prefs.setBool('churnNotificationEnabled', json['churnNotificationEnabled']);

    // 設定変更時に通知を再スケジュール
    await cancelAllNotifications();
    // マスタースイッチがONの場合のみ通知をスケジュール
    if (settings.notificationEnabled) {
      if (settings.habitNotificationEnabled) {
        await scheduleHabitNotification(
          time: settings.notificationTime,
          onlyWhenNoInput: settings.condition == NotificationCondition.onlyWhenNoInput,
        );
      }
      if (settings.churnNotificationEnabled) {
        await scheduleChurnNotification();
      }
    }
  }

  Future<void> scheduleHabitNotification({
    required TimeOfDay time,
    required bool onlyWhenNoInput,
  }) async {
    // 習慣化フェーズ通知をスケジュール
    // 注: flutter_local_notificationsは日次通知をサポートしているが、
    // 「入力がない日のみ」の条件は実行時にチェックする必要があります

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // もし今日の通知時刻が過ぎていたら、明日にスケジュール
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const notificationDetails = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // ランダムなメッセージを選択
    final randomMessage = _habitMessages[Random().nextInt(_habitMessages.length)];

    // 日次繰り返し通知
    await _notifications.zonedSchedule(
      0, // 習慣化通知のID
      '家計簿ポン',
      randomMessage,
      _nextInstanceOfTime(time),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // 次の通知時刻を計算
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tokyo = tz.getLocation('Asia/Tokyo');
    final now = tz.TZDateTime.now(tokyo);
    var scheduledDate = tz.TZDateTime(
      tokyo,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> scheduleChurnNotification() async {
    // 離脱フェーズ通知をスケジュール
    final lastInputDate = await _getLastInputDate();
    if (lastInputDate == null) return;

    final daysSinceLastInput = DateTime.now().difference(lastInputDate).inDays;

    // 30日未満なら通知不要
    if (daysSinceLastInput < 30) return;

    // 次の収入日を予測
    final nextIncomeDate = await _predictNextIncomeDate();
    if (nextIncomeDate == null) return;

    // 予測日の8日前に通知
    final notificationDate = nextIncomeDate.subtract(const Duration(days: 8));

    // 猶予期間チェック: 30日目から予測日の7日前まで
    final gracePeriodEnd = nextIncomeDate.subtract(const Duration(days: 7));
    final now = DateTime.now();

    if (now.isBefore(notificationDate.subtract(const Duration(days: 30))) ||
        now.isAfter(gracePeriodEnd)) {
      return; // 猶予期間外
    }

    const notificationDetails = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final tokyo = tz.getLocation('Asia/Tokyo');
    final tzNotificationDate = tz.TZDateTime.from(notificationDate, tokyo);

    await _notifications.zonedSchedule(
      1, // 離脱通知のID
      '家計簿ポン',
      _churnMessage,
      tzNotificationDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<DateTime?> _predictNextIncomeDate() async {
    // 収入タイプの優先度: 給料日 > その他 > 副収入
    final priorities = ['給与', 'その他', '副収入'];

    for (final incomeType in priorities) {
      final predictedDate = await _predictFromIncomeType(incomeType);
      if (predictedDate != null) {
        return predictedDate;
      }
    }

    return null;
  }

  Future<DateTime?> _predictFromIncomeType(String incomeType) async {
    final incomes = await _storage.getIncomes();
    final filteredIncomes = incomes
        .where((income) => income.incomeType == incomeType)
        .toList();

    if (filteredIncomes.isEmpty) return null;

    // 最も多い日付（日）を特定
    final Map<int, int> dayFrequency = {};
    for (final income in filteredIncomes) {
      final day = income.date.day;
      dayFrequency[day] = (dayFrequency[day] ?? 0) + 1;
    }

    // 最頻出の日を取得
    int mostCommonDay = dayFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // 次回の該当日を計算
    final now = DateTime.now();
    var nextDate = DateTime(now.year, now.month, mostCommonDay);

    // 月の最終日を超える場合は調整
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    if (mostCommonDay > lastDayOfMonth) {
      mostCommonDay = lastDayOfMonth;
      nextDate = DateTime(now.year, now.month, mostCommonDay);
    }

    // すでに過ぎていたら翌月に
    if (nextDate.isBefore(now)) {
      nextDate = DateTime(now.year, now.month + 1, mostCommonDay);
      final nextLastDay = DateTime(now.year, now.month + 2, 0).day;
      if (mostCommonDay > nextLastDay) {
        nextDate = DateTime(now.year, now.month + 1, nextLastDay);
      }
    }

    return nextDate;
  }

  Future<DateTime?> _getLastInputDate() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastInputDateKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> updateLastInputDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastInputDateKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
