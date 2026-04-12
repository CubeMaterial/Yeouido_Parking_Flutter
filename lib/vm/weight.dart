const hours = [
  '07','08','09','10','11','12','13','14',
  '15','16','17','18','19','20','21','22'
];

class TrafficRow {
  final DateTime date;
  final Map<String, double> traffic; // keys: "07"..."22"
  const TrafficRow(this.date, this.traffic);
}

double median(List<double> values) {
  final s = [...values]..sort();
  final m = s.length ~/ 2;
  return s.length.isEven ? (s[m - 1] + s[m]) / 2 : s[m];
}

// Preprocess: 2025 traffic -> weekday/hour weights
Map<int, Map<String, double>> buildWeekdayWeights(List<TrafficRow> rows) {
  final buckets = <int, Map<String, List<double>>>{};

  for (final row in rows.where((r) => r.date.year == 2025)) {
    final day = row.date.weekday; // Mon=1...Sun=7
    final byHour = buckets.putIfAbsent(day, () => {});
    for (final h in hours) {
      final v = row.traffic[h];
      if (v != null) byHour.putIfAbsent(h, () => []).add(v);
    }
  }

  final result = <int, Map<String, double>>{};
  for (var day = 1; day <= 7; day++) {
    final byHour = buckets[day];
    if (byHour == null || hours.any((h) => (byHour[h] ?? const []).isEmpty)) continue;

    final med = {for (final h in hours) h: median(byHour[h]!)};
    final minV = med.values.reduce((a, b) => a < b ? a : b);
    final maxV = med.values.reduce((a, b) => a > b ? a : b);

    final scaled = {
      for (final h in hours) h: maxV == minV ? 1.0 : (med[h]! - minV) / (maxV - minV)
    };

    final sum = scaled.values.fold(0.0, (a, b) => a + b);
    result[day] = {
      for (final h in hours) h: sum > 0 ? scaled[h]! / sum : 1.0 / hours.length
    };
  }
  return result;
}

int _clampRound(double v, int maxCapacity) {
  if (!v.isFinite || v < 0) return 0;
  if (v > maxCapacity) return maxCapacity;
  return v.round();
}

// Runtime: one anchor count -> all hours
Map<String, int> estimateParking({
  required Map<String, int> target,
  required int maxCapacity,
  required int weekday,
  required Map<int, Map<String, double>> weightsByWeekday,
}) {
  const eps = 1e-9;
  if (target.isEmpty) return {};

  final anchor = target.entries.first;
  final weights = weightsByWeekday[weekday];
  if (!hours.contains(anchor.key) || weights == null) return {};

  double safe(double? w) => (w ?? 0) > eps ? w! : eps;
  final anchorWeight = safe(weights[anchor.key]);

  return {
    for (final h in hours)
      h: _clampRound(anchor.value * safe(weights[h]) / anchorWeight, maxCapacity)
  };
}

// Example
// final weightsByWeekday = buildWeekdayWeights(rows2025);
// final result = estimateParking(
//   target: {'13': 125},
//   maxCapacity: 670,
//   weekday: 1, // Monday
//   weightsByWeekday: weightsByWeekday,
// );
