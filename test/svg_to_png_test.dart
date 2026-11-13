import 'dart:ui' as ui;

import 'package:ecg_studio/services/svg_to_png.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rasterizes SVG to a PNG within the requested dimensions', () async {
    const svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 10">
  <rect x="1" y="1" width="18" height="8" fill="#e55261"/>
</svg>
''';

    final png = await svgToPng(svg, maxDimension: 64);
    final codec = await ui.instantiateImageCodec(png);
    final image = (await codec.getNextFrame()).image;

    expect(image.width, 64);
    expect(image.height, 32);

    image.dispose();
    codec.dispose();
  });
}
