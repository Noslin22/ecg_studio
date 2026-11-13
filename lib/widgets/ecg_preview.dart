import 'package:ecg_studio/core/csv_processor.dart';
import 'package:ecg_studio/core/ecg_preview_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'preview_card.dart';

class EcgPreview extends StatelessWidget {
  const EcgPreview({
    required this.points,
    required this.color,
    required this.strokeWidth,
    super.key,
  });

  final List<EcgPoint> points;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final signal = points.length < 2
        ? _emptyMessage('Carregue dados CSV para ver o ECG')
        : SvgPicture.string(
            createEcgPreviewSvg(
              points: points,
              color: color,
              strokeWidth: strokeWidth,
            ),
            width: 1200,
            height: 520,
            fit: BoxFit.contain,
            semanticsLabel: 'Sinal ECG concatenado em linha reta',
          );
    return PreviewCard(
      title: 'ECG concatenado',
      detail: '${points.length} pontos · sinal em linha reta',
      child: signal,
    );
  }

  Widget _emptyMessage(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 40, color: Color(0xFF747C8C)),
      ),
    );
  }
}
