import 'package:flutter/material.dart';

enum NotificationCondition {
  onlyWhenNoInput,
  daily,
}

class NotificationSettings {
  final bool notificationEnabled; // マスタースイッチ
  final bool habitNotificationEnabled;
  final TimeOfDay notificationTime;
  final NotificationCondition condition;
  final bool churnNotificationEnabled;

  const NotificationSettings({
    required this.notificationEnabled,
    required this.habitNotificationEnabled,
    required this.notificationTime,
    required this.condition,
    required this.churnNotificationEnabled,
  });

  factory NotificationSettings.defaultSettings() {
    return const NotificationSettings(
      notificationEnabled: false,
      habitNotificationEnabled: false,
      notificationTime: TimeOfDay(hour: 21, minute: 0),
      condition: NotificationCondition.onlyWhenNoInput,
      churnNotificationEnabled: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationEnabled': notificationEnabled,
      'habitNotificationEnabled': habitNotificationEnabled,
      'notificationTimeHour': notificationTime.hour,
      'notificationTimeMinute': notificationTime.minute,
      'condition': condition.index,
      'churnNotificationEnabled': churnNotificationEnabled,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      notificationEnabled: json['notificationEnabled'] ?? false,
      habitNotificationEnabled: json['habitNotificationEnabled'] ?? false,
      notificationTime: TimeOfDay(
        hour: json['notificationTimeHour'] ?? 21,
        minute: json['notificationTimeMinute'] ?? 0,
      ),
      condition: NotificationCondition.values[json['condition'] ?? 0],
      churnNotificationEnabled: json['churnNotificationEnabled'] ?? true,
    );
  }

  NotificationSettings copyWith({
    bool? notificationEnabled,
    bool? habitNotificationEnabled,
    TimeOfDay? notificationTime,
    NotificationCondition? condition,
    bool? churnNotificationEnabled,
  }) {
    return NotificationSettings(
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      habitNotificationEnabled: habitNotificationEnabled ?? this.habitNotificationEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      condition: condition ?? this.condition,
      churnNotificationEnabled: churnNotificationEnabled ?? this.churnNotificationEnabled,
    );
  }
}
