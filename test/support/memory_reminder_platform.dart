import 'package:freshkeep/features/reminders/domain/reminders.dart';

class MemoryReminderPlatform implements ReminderPlatform {
  bool allowed = true, failSchedule = false;
  int requests = 0, schedules = 0, cancels = 0;
  final jobs =
      <
        int,
        ({
          DateTime date,
          String zone,
          String title,
          String body,
          String payload,
        })
      >{};
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> permitted() async => allowed;
  @override
  Future<bool> requestPermission() async {
    requests++;
    return allowed;
  }

  @override
  Future<String> timezone() async => 'Europe/London';
  @override
  Future<List<PendingReminder>> pending() async =>
      jobs.entries.map((e) => PendingReminder(e.key, e.value.payload)).toList();
  @override
  Future<void> cancel(int id) async {
    cancels++;
    jobs.remove(id);
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime localDate,
    required String zone,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (failSchedule) throw StateError('schedule failed');
    schedules++;
    jobs[id] = (
      date: localDate,
      zone: zone,
      title: title,
      body: body,
      payload: payload,
    );
  }
}
