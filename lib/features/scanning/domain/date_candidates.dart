import '../../inventory/domain/food_item.dart';

enum PrintedDateKind { expiry, bestBefore, manufacture, unknown }

class DateCandidate {
  const DateCandidate(
    this.date,
    this.kind,
    this.evidence, {
    this.ambiguous = false,
  });
  final DateTime date;
  final PrintedDateKind kind;
  final String evidence;
  final bool ambiguous;
  DateKind get foodKind => switch (kind) {
    PrintedDateKind.expiry => DateKind.expiry,
    PrintedDateKind.bestBefore => DateKind.bestBefore,
    _ => DateKind.unknown,
  };
}

String normalizeDigits(String text) {
  var result = text;
  for (var i = 0; i < 10; i++) {
    result = result
        .replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i')
        .replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i');
  }
  return result;
}

/// Conservative civil-date parsing: no fabricated day for month/year labels,
/// no inference of expiry from manufacture, and no silent MDY/DMY choice.
List<DateCandidate> parseDateCandidates(String input) {
  final lines = normalizeDigits(input).split('\n');
  final results = <DateCandidate>[];
  final numeric = RegExp(
    r'(?<!\d)(\d{1,4})\s*[/\.\-]\s*(\d{1,2})\s*[/\.\-]\s*(\d{2,4})(?!\d)',
  );
  final named = RegExp(
    r'(?<!\d)(\d{1,2})\s*[- /]?\s*(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[A-Z]*\s*[- /]?\s*(\d{2,4})(?!\d)',
    caseSensitive: false,
  );
  PrintedDateKind label(String line) {
    final upper = line.toUpperCase();
    if (RegExp(r'\b(MFG|MFD|MANUFACTURED|PROD|PRODUCTION)\b|إنتاج|انتاج|صنع')
        .hasMatch(upper)) {
      return PrintedDateKind.manufacture;
    }
    if (RegExp(r'BEST\s*(BEFORE|BY)|\bBBE?\b|يفضل|الأفضل|الافضل')
        .hasMatch(upper)) {
      return PrintedDateKind.bestBefore;
    }
    if (RegExp(r'\b(EXP|EXPIRY|EXPIRES|USE\s*BY)\b|انتهاء|إنتهاء|صالح حتى')
        .hasMatch(upper)) {
      return PrintedDateKind.expiry;
    }
    return PrintedDateKind.unknown;
  }

  void add(
    int year,
    int month,
    int day,
    PrintedDateKind kind,
    String evidence,
    bool ambiguous,
  ) {
    if (year < 100) year += 2000;
    if (year < 1900 ||
        year > 2200 ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31) {
      return;
    }
    final date = DateTime(year, month, day);
    if (date.month != month || date.day != day) return;
    if (!results.any((r) => r.date == date && r.kind == kind)) {
      results.add(
        DateCandidate(date, kind, evidence.trim(), ambiguous: ambiguous),
      );
    }
  }

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    for (final match in numeric.allMatches(line)) {
      // Bind each date to its nearest preceding label on the same line.
      var context = line.substring(0, match.start);
      final previousDates = numeric.allMatches(context).toList();
      if (previousDates.isNotEmpty) {
        context = context.substring(previousDates.last.end);
      }
      var kind = label(context);
      if (kind == PrintedDateKind.unknown &&
          numeric.allMatches(line).length == 1) {
        kind = label(line);
        if (kind == PrintedDateKind.unknown &&
            i > 0 &&
            !numeric.hasMatch(lines[i - 1])) {
          kind = label(lines[i - 1]);
        }
      }
      final a = int.parse(match[1]!),
          b = int.parse(match[2]!),
          c = int.parse(match[3]!);
      if (match[1]!.length == 4) {
        add(a, b, c, kind, line, false);
      } else {
        final ambiguous = a <= 12 && b <= 12 && a != b;
        add(c, b, a, kind, line, ambiguous);
        if (ambiguous || (b > 12 && a <= 12)) {
          add(c, a, b, kind, line, ambiguous);
        }
      }
    }
    for (final match in named.allMatches(line)) {
      final month =
          [
            'JAN',
            'FEB',
            'MAR',
            'APR',
            'MAY',
            'JUN',
            'JUL',
            'AUG',
            'SEP',
            'OCT',
            'NOV',
            'DEC',
          ].indexOf(match[2]!.toUpperCase()) +
          1;
      add(
        int.parse(match[3]!),
        month,
        int.parse(match[1]!),
        label(line),
        line,
        false,
      );
    }
  }
  results.sort(
    (a, b) => (a.kind == PrintedDateKind.manufacture ? 1 : 0).compareTo(
      b.kind == PrintedDateKind.manufacture ? 1 : 0,
    ),
  );
  return results;
}
