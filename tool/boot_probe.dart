// Emulator-only probe. Build explicitly with -t tool/boot_probe.dart.
// This file is never imported by the application's normal entry point.
import 'package:flutter/material.dart';
import 'package:freshkeep/features/reminders/data/android_reminder_platform.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final platform = AndroidReminderPlatform();
  await platform.initialize();
  const verify = bool.fromEnvironment('VERIFY_BOOT');
  if (verify) {
    final pending = await platform.pending();
    if (!pending.any(
      (p) => p.id == 1900400001 && p.payload == 'freshkeep-reboot-test-only',
    )) {
      throw StateError('Reboot fixture missing');
    }
    await platform.cancel(1900400001);
    if ((await platform.pending()).any((p) => p.id == 1900400001)) {
      throw StateError('Reboot fixture cancellation failed');
    }
    debugPrint('FRESHKEEP_BOOT_VERIFIED_AND_CLEANED');
  } else {
    await platform.cancel(1900400001);
    await platform.schedule(
      id: 1900400001,
      localDate: DateTime.now().add(const Duration(days: 2)),
      zone: await platform.timezone(),
      title: 'FreshKeep reboot probe',
      body: 'Isolated test fixture',
      payload: 'freshkeep-reboot-test-only',
    );
    if (!(await platform.pending()).any((p) => p.id == 1900400001)) {
      throw StateError('Fixture not scheduled');
    }
    debugPrint('FRESHKEEP_BOOT_FIXTURE_READY');
  }
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            verify
                ? 'Boot probe verified and cleaned'
                : 'Boot probe scheduled · test fixture',
          ),
        ),
      ),
    ),
  );
}
