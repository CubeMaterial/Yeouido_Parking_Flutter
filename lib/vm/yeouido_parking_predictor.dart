import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class YeouidoParkingWeights2024 {
  YeouidoParkingWeights2024({required this.weekday, required this.holiday});

  static const assetPath = 'lib/vm/yeouido_weights_2024.json';

  final Map<String, double> weekday;
  final Map<String, double> holiday;

  static Future<YeouidoParkingWeights2024> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('weights json root is not an object');
    }

    final weights = decoded['weights'];
    if (weights is! Map<String, dynamic>) {
      throw const FormatException('weights json missing "weights"');
    }

    Map<String, double> parseBucket(Object? value) {
      if (value is! Map) return const {};
      final result = <String, double>{};
      for (final entry in value.entries) {
        final key = entry.key?.toString();
        final v = entry.value;
        if (key == null) continue;
        if (v is num) {
          result[key] = v.toDouble();
        } else {
          final parsed = double.tryParse(v?.toString() ?? '');
          if (parsed != null) result[key] = parsed;
        }
      }
      return result;
    }

    return YeouidoParkingWeights2024(
      weekday: parseBucket(weights['weekday']),
      holiday: parseBucket(weights['holiday']),
    );
  }

  Map<String, double> weightsFor(DateTime when) {
    final isHoliday =
        when.weekday == DateTime.saturday || when.weekday == DateTime.sunday;
    return isHoliday ? holiday : weekday;
  }

  int? predictAvailableAfter({
    required int currentAvailable,
    required int totalCapacity,
    required DateTime now,
    required Duration after,
  }) {
    final target = now.add(after);
    final weights = weightsFor(now);

    final nowKey = now.hour.toString().padLeft(2, '0');
    final targetKey = target.hour.toString().padLeft(2, '0');

    final wNow = weights[nowKey];
    final wTarget = weights[targetKey];
    if (wNow == null || wTarget == null) return null;

    const eps = 1e-9;
    final safeNow = wNow > eps ? wNow : eps;
    final safeTarget = wTarget > eps ? wTarget : eps;

    final predicted = (currentAvailable * safeTarget / safeNow).round();
    if (predicted < 0) return 0;
    if (predicted > totalCapacity) return totalCapacity;
    return predicted;
  }
}
