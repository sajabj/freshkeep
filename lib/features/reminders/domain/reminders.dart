import '../../inventory/domain/food_item.dart';

class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.hour = 9,
    this.minute = 0,
    this.days = const [7, 3, 1, 0],
  });
  final bool enabled;
  final int hour, minute;
  final List<int> days;
  void validate() {
    if (hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        days.isEmpty ||
        days.length > 8 ||
        days.toSet().length != days.length ||
        days.any((d) => d < 0 || d > 365)) {
      throw ArgumentError('Invalid reminder settings');
    }
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
    'days': days,
  };
  factory ReminderSettings.fromJson(Map<String, dynamic> m) => ReminderSettings(
    enabled: m['enabled'] as bool,
    hour: m['hour'] as int,
    minute: m['minute'] as int,
    days: List<int>.from(m['days'] as List),
  );
  ReminderSettings copy({
    bool? enabled,
    int? hour,
    int? minute,
    List<int>? days,
  }) => ReminderSettings(
    enabled: enabled ?? this.enabled,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    days: days ?? this.days,
  );
}

class ReminderPlan {
  ReminderPlan(this.food, this.days, this.at);
  final FoodItem food;
  final int days;
  final DateTime at;
}

List<ReminderPlan> planReminders(
  List<FoodItem> items,
  ReminderSettings settings,
  DateTime now,
) {
  settings.validate();
  if (!settings.enabled) return [];
  final result = <ReminderPlan>[];
  for (final food in items.where((f) => f.status == FoodStatus.available)) {
    for (final offset in settings.days) {
      final date = DateTime(
        food.expiryDate.year,
        food.expiryDate.month,
        food.expiryDate.day - offset,
        settings.hour,
        settings.minute,
      );
      if (date.isAfter(now)) result.add(ReminderPlan(food, offset, date));
    }
  }
  result.sort((a, b) {
    final byDate = a.at.compareTo(b.at);
    if (byDate != 0) return byDate;
    final byId = a.food.id.compareTo(b.food.id);
    return byId != 0 ? byId : a.days.compareTo(b.days);
  });
  return result;
}

class PendingReminder {
  PendingReminder(this.id, this.payload);
  final int id;
  final String? payload;
}

abstract class ReminderPlatform {
  Future<void> initialize();
  Future<bool> permitted();
  Future<bool> requestPermission();
  Future<String> timezone();
  Future<List<PendingReminder>> pending();
  Future<void> schedule({
    required int id,
    required DateTime localDate,
    required String zone,
    required String title,
    required String body,
    required String payload,
  });
  Future<void> cancel(int id);
}

class ReminderStatus {
  const ReminderStatus({
    this.scheduled = 0,
    this.total = 0,
    this.blocked = false,
  });
  final int scheduled, total;
  final bool blocked;
}

class NotificationPermissionDenied implements Exception {
  const NotificationPermissionDenied();
}
