import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Returns a color representing parking availability.
///
/// - `available / total == 1.0` → green
/// - `available / total == 0.0` → red
/// - `unknown == true` → neutral grey
Color parkingAvailabilityColor({
  required int available,
  required int total,
  bool unknown = false,
}) {
  if (unknown) return const Color(0xFF9E9E9E);
  if (total <= 0) return const Color(0xFFD50000);

  final t = (available / total).clamp(0.0, 1.0);
  final hue = lerpDouble(0, 120, t) ?? 0; // 0=red, 120=green

  return HSLColor.fromAHSL(1.0, hue, 0.85, 0.45).toColor();
}
