enum CookingTimerState { running, paused, finished }

class CookingTimer {
  const CookingTimer({
    required this.notificationId,
    required this.id,
    required this.name,
    required this.durationSeconds,
    required this.remainingSeconds,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.endAt,
    this.notified = false,
  });
  final int notificationId, durationSeconds, remainingSeconds;
  final String id, name;
  final DateTime? endAt;
  final CookingTimerState state;
  final bool notified;
  final DateTime createdAt, updatedAt;
  int remainingAt(DateTime now) {
    if (state == CookingTimerState.finished) return 0;
    if (state == CookingTimerState.paused || endAt == null) {
      return remainingSeconds;
    }
    return endAt!.difference(now).inSeconds.clamp(0, durationSeconds);
  }

  double progressAt(DateTime now) =>
      durationSeconds == 0 ? 0 : remainingAt(now) / durationSeconds;
  Map<String, Object?> toMap({bool includeNotificationId = false}) => {
    if (includeNotificationId) 'notification_id': notificationId,
    'id': id,
    'name': name,
    'duration_seconds': durationSeconds,
    'remaining_seconds': remainingSeconds,
    'end_at': endAt?.toUtc().toIso8601String(),
    'state': state.name,
    'notified': notified ? 1 : 0,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
  factory CookingTimer.fromMap(Map<String, Object?> m) => CookingTimer(
    notificationId: 100000 + (m['notification_id'] as int),
    id: m['id'] as String,
    name: m['name'] as String,
    durationSeconds: m['duration_seconds'] as int,
    remainingSeconds: m['remaining_seconds'] as int,
    endAt: m['end_at'] == null
        ? null
        : DateTime.parse(m['end_at'] as String).toLocal(),
    state: CookingTimerState.values.byName(m['state'] as String),
    notified: m['notified'] == 1,
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: DateTime.parse(m['updated_at'] as String),
  );
}
