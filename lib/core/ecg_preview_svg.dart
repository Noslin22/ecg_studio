import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'csv_processor.dart';

String createEcgPreviewSvg({
  required List<EcgPoint> points,
  required Color color,
  required double strokeWidth,
}) {
  const width = 1200.0;
  const height = 520.0;
  const horizontalPadding = 12.0;
  if (points.length < 2) {
    throw ArgumentError('São necessários pelo menos dois pontos para o ECG.');
  }

  final values = points.map((point) => point.amplitude).toList();
  final sortedValues = [...values]..sort();
  final baseline = sortedValues[sortedValues.length ~/ 2];
  final peak = values.map((value) => (value - baseline).abs()).reduce(math.max);
  final safePeak = peak == 0 ? 1.0 : peak;
  final path = StringBuffer();

  for (var index = 0; index < points.length; index++) {
    final x =
        horizontalPadding +
        (width - horizontalPadding * 2) * index / (points.length - 1);
    final normalized = (points[index].amplitude - baseline) / safePeak;
    final y = height * (0.5 - normalized * 0.38);
    path
      ..write(index == 0 ? 'M ' : ' L ')
      ..write(x.toStringAsFixed(2))
      ..write(' ')
      ..write(y.toStringAsFixed(2));
  }

  final colorHex = color
      .toARGB32()
      .toRadixString(16)
      .substring(2)
      .toUpperCase();
  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $width $height">
  <path d="${path.toString()}" fill="none" stroke="#$colorHex" stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';
}
