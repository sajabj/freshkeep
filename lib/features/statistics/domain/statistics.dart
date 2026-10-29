import 'dart:convert';

import '../../inventory/domain/food_item.dart';

enum TrendPeriod { weekly, monthly }

class Outcome {
  const Outcome(this.id, this.status, this.at, this.price);
  final String id;
  final FoodStatus status;
  final DateTime at;
  final double? price;
}

class OutcomeTotals {
  OutcomeTotals(Iterable<Outcome> outcomes) {
    for (final o in outcomes) {
      if (o.status == FoodStatus.used) {
        used++;
        if (o.price != null) {
          usedValue += o.price!;
          usedPriced++;
        }
      } else {
        discarded++;
        if (o.price != null) {
          discardedValue += o.price!;
          discardedPriced++;
        }
      }
    }
  }
  int used = 0, discarded = 0, usedPriced = 0, discardedPriced = 0;
  double usedValue = 0, discardedValue = 0;
}

class TrendBucket {
  TrendBucket(this.start, this.end, this.totals);
  final DateTime start, end;
  final OutcomeTotals totals;
}

class InventoryStatistics {
  InventoryStatistics(this.outcomes, {this.invalidEvents = 0});
  final List<Outcome> outcomes;
  final int invalidEvents;

  /// Events are ordered by instant then revision, not UUID. A restoration
  /// reverses an earlier outcome; deletion retains history via snapshot.id.
  factory InventoryStatistics.fromRows(
    List<Map<String, Object?>> events,
    List<Map<String, Object?>> inventory,
  ) {
    final latest =
        <String, ({DateTime at, int revision, Map<String, dynamic> data})>{};
    var invalid = 0;
    for (final row in events) {
      try {
        final data =
            jsonDecode(row['snapshot'] as String) as Map<String, dynamic>;
        final id = data['id'] as String;
        final at = DateTime.parse(row['occurred_at'] as String);
        final revision = data['revision'] as int;
        FoodStatus.values.byName(data['status'] as String);
        if (id.isEmpty) throw const FormatException();
        final previous = latest[id];
        if (previous == null ||
            revision > previous.revision ||
            (revision == previous.revision && at.isAfter(previous.at))) {
          latest[id] = (at: at, revision: revision, data: data);
        }
      } catch (_) {
        invalid++;
      }
    }
    // Inventory is authoritative for retained batches, including legacy v1 rows
    // without audit history. Archived legacy rows need a real status timestamp.
    for (final row in inventory) {
      final id = row['id'] as String;
      latest[id] = (
        at: DateTime.parse(row['updated_at'] as String),
        revision: row['revision'] as int,
        data: Map<String, dynamic>.from(row),
      );
    }
    final outcomes = <Outcome>[];
    for (final entry in latest.entries) {
      try {
        final data = entry.value.data;
        final status = FoodStatus.values.byName(data['status'] as String);
        if (status == FoodStatus.available) continue;
        final at = DateTime.parse(data['status_changed_at'] as String)
            .toLocal();
        final raw = data['price'];
        final price = raw is num && raw.isFinite && raw >= 0
            ? raw.toDouble()
            : null;
        outcomes.add(Outcome(entry.key, status, at, price));
      } catch (_) {
        invalid++;
      }
    }
    return InventoryStatistics(outcomes, invalidEvents: invalid);
  }

  List<TrendBucket> trend(DateTime now, TrendPeriod period) {
    final today = calendarDate(now);
    final current = period == TrendPeriod.weekly
        ? DateTime(today.year, today.month, today.day - today.weekday + 1)
        : DateTime(today.year, today.month);
    DateTime offset(int n) => period == TrendPeriod.weekly
        ? DateTime(current.year, current.month, current.day + n * 7)
        : DateTime(current.year, current.month + n);
    return [
      for (var i = -5; i <= 0; i++)
        TrendBucket(
          offset(i),
          offset(i + 1),
          OutcomeTotals(
            outcomes.where(
              (o) =>
                  !o.at.isBefore(offset(i)) &&
                  o.at.isBefore(offset(i + 1)) &&
                  !o.at.isAfter(now),
            ),
          ),
        ),
    ];
  }

  OutcomeTotals totals(DateTime now) =>
      OutcomeTotals(outcomes.where((o) => !o.at.isAfter(now)));
}
