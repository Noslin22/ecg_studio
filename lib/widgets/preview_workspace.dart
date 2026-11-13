import 'package:ecg_studio/core/csv_processor.dart';
import 'package:flutter/material.dart';

import 'ecg_preview.dart';
import 'svg_preview.dart';

class PreviewWorkspace extends StatelessWidget {
  const PreviewWorkspace({
    required this.points,
    required this.strokeColor,
    required this.strokeWidth,
    required this.originalSvg,
    required this.originalSvgName,
    required this.resultSvg,
    required this.amplitude,
    required this.onExport,
    required this.isWide,
    super.key,
  });

  static const _muted = Color(0xFF9299AA);

  final List<EcgPoint> points;
  final Color strokeColor;
  final double strokeWidth;
  final String originalSvg;
  final String originalSvgName;
  final String resultSvg;
  final double amplitude;
  final VoidCallback onExport;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final ecgPreview = EcgPreview(
      points: points,
      color: strokeColor,
      strokeWidth: strokeWidth,
    );
    final originalPreview = SvgPreview(
      title: 'SVG original',
      detail: originalSvgName,
      svgXml: originalSvg,
      emptyMessage: 'Selecione um arquivo SVG',
      semanticsLabel: 'SVG original selecionado',
    );
    final resultPreview = SvgPreview(
      title: 'Imagem final',
      detail: resultSvg.isEmpty
          ? 'Aguardando arquivos compatíveis'
          : '${amplitude.toStringAsFixed(1)}× · ${strokeWidth.toStringAsFixed(1)} px',
      svgXml: resultSvg,
      emptyMessage: 'Selecione um SVG e arquivos CSV',
      semanticsLabel: 'Resultado ECG sobre o SVG original',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final previews = constraints.maxHeight.isFinite
            ? _buildFlexiblePreviews(
                isWide: isWide,
                ecgPreview: ecgPreview,
                originalPreview: originalPreview,
                resultPreview: resultPreview,
              )
            : _buildScrollablePreviews(
                ecgPreview: ecgPreview,
                originalPreview: originalPreview,
                resultPreview: resultPreview,
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildToolbar(),
            const SizedBox(height: 14),
            if (constraints.maxHeight.isFinite)
              Expanded(child: previews)
            else
              previews,
          ],
        );
      },
    );
  }

  Widget _buildToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        return Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pré-visualização',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Confira os dados, o SVG de origem e o resultado',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                ],
              ),
            ),
            if (compact) ...[
              const Tooltip(
                message: 'Roda do mouse ou pinça para zoom',
                child: Icon(Icons.zoom_in, size: 17, color: _muted),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: resultSvg.isEmpty ? null : onExport,
                tooltip: 'Exportar',
                icon: const Icon(Icons.download_outlined, size: 19),
              ),
            ] else ...[
              const Icon(Icons.mouse_outlined, size: 15, color: _muted),
              const SizedBox(width: 6),
              const Text(
                'Roda / pinça para zoom',
                style: TextStyle(fontSize: 10, color: _muted),
              ),
              const SizedBox(width: 14),
              OutlinedButton.icon(
                onPressed: resultSvg.isEmpty ? null : onExport,
                icon: const Icon(Icons.download_outlined, size: 17),
                label: const Text('Exportar'),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFlexiblePreviews({
    required bool isWide,
    required Widget ecgPreview,
    required Widget originalPreview,
    required Widget resultPreview,
  }) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(flex: 2, child: ecgPreview),
                const SizedBox(height: 14),
                Expanded(flex: 3, child: originalPreview),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(flex: 7, child: resultPreview),
        ],
      );
    }

    return Column(
      children: [
        Expanded(flex: 2, child: ecgPreview),
        const SizedBox(height: 14),
        Expanded(flex: 3, child: originalPreview),
        const SizedBox(height: 14),
        Expanded(flex: 4, child: resultPreview),
      ],
    );
  }

  Widget _buildScrollablePreviews({
    required Widget ecgPreview,
    required Widget originalPreview,
    required Widget resultPreview,
  }) {
    return Column(
      children: [
        AspectRatio(aspectRatio: 2.5, child: ecgPreview),
        const SizedBox(height: 14),
        AspectRatio(aspectRatio: 2.5, child: originalPreview),
        const SizedBox(height: 14),
        AspectRatio(aspectRatio: 1.6, child: resultPreview),
      ],
    );
  }
}
