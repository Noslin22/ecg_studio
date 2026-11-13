import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({
    required this.svgName,
    required this.csvNames,
    required this.amplitude,
    required this.strokeWidth,
    required this.strokeColor,
    required this.error,
    required this.onPickSvg,
    required this.onPickCsv,
    required this.onAmplitudeChanged,
    required this.onStrokeWidthChanged,
    required this.onStrokeColorChanged,
    super.key,
  });

  static const _surface = Color(0xFF191D2A);
  static const _muted = Color(0xFF9299AA);
  static const _accent = Color(0xFF8C7CFF);
  static const _colors = [
    Color(0xFFE55261),
    Color(0xFF2EAA86),
    Color(0xFF5588F5),
    Color(0xFFE49A42),
    Color(0xFF222638),
  ];

  final String svgName;
  final List<String> csvNames;
  final double amplitude;
  final double strokeWidth;
  final Color strokeColor;
  final String? error;
  final VoidCallback onPickSvg;
  final VoidCallback onPickCsv;
  final ValueChanged<double> onAmplitudeChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final ValueChanged<Color> onStrokeColorChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('ARQUIVOS', 'Escolha o traçado e os dados'),
        const SizedBox(height: 14),
        _fileTile(
          icon: Icons.image_outlined,
          label: 'Imagem vetorial',
          name: svgName,
          onTap: onPickSvg,
        ),
        const SizedBox(height: 9),
        _fileTile(
          icon: Icons.dataset_outlined,
          label: 'Dados do ECG',
          name: csvNames.isEmpty
              ? 'Selecione arquivos CSV'
              : '${csvNames.length} arquivo(s)',
          onTap: onPickCsv,
        ),
        if (csvNames.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: csvNames
                .map(
                  (name) => Chip(
                    label: Text(name, overflow: TextOverflow.ellipsis),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    labelStyle: const TextStyle(fontSize: 10, color: _muted),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 24),
        _sectionTitle('SINAL ECG', 'Ajuste a aparência do traçado'),
        const SizedBox(height: 8),
        _sliderSetting(
          title: 'Amplitude',
          value: amplitude,
          valueLabel: '${amplitude.toStringAsFixed(1)}×',
          min: 2,
          max: 30,
          divisions: 56,
          onChanged: onAmplitudeChanged,
        ),
        _sliderSetting(
          title: 'Espessura da linha',
          value: strokeWidth,
          valueLabel: '${strokeWidth.toStringAsFixed(1)} px',
          min: 0.8,
          max: 8,
          divisions: 36,
          onChanged: onStrokeWidthChanged,
        ),
        const SizedBox(height: 14),
        const Text(
          'COR DO TRAÇADO',
          style: TextStyle(
            color: _muted,
            fontSize: 10,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: _colors.map((color) {
            final selected = color == strokeColor;
            return GestureDetector(
              onTap: () => onStrokeColorChanged(color),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 15)
                    : null,
              ),
            );
          }).toList(),
        ),
        if (error != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFB63F50).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFB63F50).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              error!,
              style: const TextStyle(color: Color(0xFFFFA8B1), fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: _muted)),
      ],
    );
  }

  Widget _fileTile({
    required IconData icon,
    required String label,
    required String name,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: _accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.drive_folder_upload_outlined,
                size: 18,
                color: _muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sliderSetting({
    required String title,
    required double value,
    required String valueLabel,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 12))),
            Text(
              valueLabel,
              style: const TextStyle(
                fontSize: 11,
                color: _accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
