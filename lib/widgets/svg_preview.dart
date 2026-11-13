import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'preview_card.dart';

class SvgPreview extends StatelessWidget {
  const SvgPreview({
    required this.title,
    required this.detail,
    required this.svgXml,
    required this.emptyMessage,
    required this.semanticsLabel,
    super.key,
  });

  final String title;
  final String detail;
  final String svgXml;
  final String emptyMessage;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final preview = svgXml.isEmpty
        ? Center(
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 40, color: Color(0xFF747C8C)),
            ),
          )
        : SvgPicture.string(
            svgXml,
            width: 1200,
            height: 520,
            fit: BoxFit.contain,
            semanticsLabel: semanticsLabel,
          );

    return PreviewCard(title: title, detail: detail, child: preview);
  }
}
