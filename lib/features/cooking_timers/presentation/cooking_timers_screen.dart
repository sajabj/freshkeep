import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reminders/application/reminder_controller.dart';
import '../application/cooking_timer_controller.dart';
import '../domain/cooking_timer.dart';

String _t(BuildContext c, String ar, String en) =>
    Localizations.localeOf(c).languageCode == 'ar' ? ar : en;

class CookingTimersScreen extends ConsumerStatefulWidget {
  const CookingTimersScreen({super.key, this.suggestedMinutes});
  final int? suggestedMinutes;
  @override
  ConsumerState<CookingTimersScreen> createState() => _TimersState();
}

class _TimersState extends ConsumerState<CookingTimersScreen> {
  Timer? ticker;
  bool refreshing = false;
  @override
  void initState() {
    super.initState();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      setState(() {});
      final rows = ref.read(cookingTimersProvider).asData?.value ?? [];
      if (!refreshing &&
          rows.any(
            (t) =>
                t.state == CookingTimerState.running &&
                t.remainingAt(DateTime.now()) == 0,
          )) {
        refreshing = true;
        await ref.read(cookingTimersProvider.notifier).refresh();
        refreshing = false;
      }
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(cookingTimersProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, 'مؤقتات الطبخ', 'Cooking Timers')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-timer'),
        onPressed: () => _newTimer(context),
        icon: const Icon(Icons.add_alarm),
        label: Text(_t(context, 'مؤقت جديد', 'New timer')),
      ),
      body: SafeArea(
        child: value.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(cookingTimersProvider),
              child: Text(_t(context, 'إعادة المحاولة', 'Try again')),
            ),
          ),
          data: (timers) => timers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _t(
                        context,
                        'لا توجد مؤقتات. أنشئ مؤقتًا للفرن أو السلق.',
                        'No timers yet. Create one for the oven or boiling.',
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: timers.length + 1,
                  itemBuilder: (c, i) => i == 0
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _t(
                              c,
                              'يعتمد العدّ داخل التطبيق على وقت النهاية المحفوظ. قد يؤخر Android الإشعار بسبب البطارية أو عند إيقاف التطبيق بالقوة، ولا نضمن وقتًا دقيقًا.',
                              'In-app timing uses the saved end time. Android may delay notifications because of battery limits or force-stop; exact delivery is not guaranteed.',
                            ),
                            style: Theme.of(c).textTheme.bodySmall,
                          ),
                        )
                      : _card(c, timers[i - 1]),
                ),
        ),
      ),
    );
  }

  Widget _card(BuildContext c, CookingTimer timer) {
    final remaining = timer.remainingAt(DateTime.now());
    final h = remaining ~/ 3600,
        m = (remaining % 3600) ~/ 60,
        s = remaining % 60;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    timer.name,
                    style: Theme.of(c).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.read(cookingTimersProvider.notifier).delete(timer),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            FittedBox(
              child: Text(
                '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
                style: Theme.of(c).textTheme.displaySmall,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: timer.progressAt(DateTime.now())),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (timer.state == CookingTimerState.running && remaining > 0)
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(cookingTimersProvider.notifier).pause(timer),
                    icon: const Icon(Icons.pause),
                    label: Text(_t(c, 'إيقاف مؤقت', 'Pause')),
                  )
                else if (remaining > 0)
                  FilledButton.icon(
                    onPressed: () =>
                        ref.read(cookingTimersProvider.notifier).resume(timer),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(_t(c, 'بدء / استكمال', 'Start / resume')),
                  ),
                TextButton(
                  onPressed: () =>
                      ref.read(cookingTimersProvider.notifier).reset(timer),
                  child: Text(_t(c, 'إعادة ضبط', 'Reset')),
                ),
              ],
            ),
            if (remaining == 0)
              Text(
                _t(c, 'انتهى المؤقت', 'Timer finished'),
                style: TextStyle(
                  color: Theme.of(c).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _newTimer(BuildContext c) async {
    final name = TextEditingController();
    final suggested = widget.suggestedMinutes ?? 0;
    var hours = suggested ~/ 60, minutes = suggested % 60, seconds = 0;
    final result = await showDialog<bool>(
      context: c,
      builder: (d) => StatefulBuilder(
        builder: (d, set) => AlertDialog(
          title: Text(_t(d, 'مؤقت جديد', 'New timer')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: _t(d, 'اسم المؤقت', 'Timer name'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final entry in [
                      ('h', hours, 23),
                      ('m', minutes, 59),
                      ('s', seconds, 59),
                    ])
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: entry.$2,
                          decoration: InputDecoration(labelText: entry.$1),
                          items: [
                            for (var i = 0; i <= entry.$3; i++)
                              DropdownMenuItem(value: i, child: Text('$i')),
                          ],
                          onChanged: (v) => set(() {
                            if (entry.$1 == 'h') hours = v!;
                            if (entry.$1 == 'm') minutes = v!;
                            if (entry.$1 == 's') seconds = v!;
                          }),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(_t(d, 'إلغاء', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text(_t(d, 'بدء', 'Start')),
            ),
          ],
        ),
      ),
    );
    if (result == true && mounted) {
      final total = hours * 3600 + minutes * 60 + seconds;
      if (name.text.trim().isEmpty || total <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                context,
                'أدخل اسمًا ومدة أكبر من صفر.',
                'Enter a name and a duration above zero.',
              ),
            ),
          ),
        );
      } else {
        final platform = ref.read(reminderPlatformProvider);
        if (!await platform.permitted()) await platform.requestPermission();
        await ref.read(cookingTimersProvider.notifier).create(name.text, total);
      }
    }
    name.dispose();
  }
}
