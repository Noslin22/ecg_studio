import 'dart:ui' as ui;

import 'package:ecg_studio/core/ecg_processor.dart';
import 'package:ecg_studio/services/svg_to_png.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  test('fits the generated drawing and overrides source path styles', () async {
    const sourceSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="800" viewBox="0 0 1000 800">
  <path d="M 10 10 L 90 10" style="fill: black; stroke: black; stroke-width: 1"/>
</svg>
''';
    const csv = 'time,voltage\n0,0\n1,1\n2,0';

    final transformed = EcgProcessor.transform(
      svgXml: sourceSvg,
      csvText: csv,
      amplitude: 5,
    );
    final styled = EcgProcessor.styleSvg(
      svgXml: transformed,
      strokeColor: '#E55261',
      strokeWidth: 4,
    );
    final document = XmlDocument.parse(styled);
    final root = document.rootElement;
    final viewBox = root
        .getAttribute('viewBox')!
        .split(RegExp(r'\s+'))
        .map(double.parse)
        .toList();
    final pathStyle = root
        .findAllElements('path')
        .single
        .getAttribute('style')!;

    expect(viewBox[2], lessThan(200));
    expect(viewBox[3], lessThan(200));
    expect(double.parse(root.getAttribute('width')!), viewBox[2]);
    expect(double.parse(root.getAttribute('height')!), viewBox[3]);
    expect(pathStyle, contains('fill: none !important'));
    expect(pathStyle, contains('stroke: #E55261 !important'));
    expect(pathStyle, contains('stroke-width: 4.0 !important'));
    expect(pathStyle, isNot(contains('stroke: black')));

    final png = await svgToPng(styled, maxDimension: 200);
    final codec = await ui.instantiateImageCodec(png);
    final image = (await codec.getNextFrame()).image;
    final pixels = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    var left = image.width;
    var right = 0;
    var pinkPixels = 0;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final offset = (y * image.width + x) * 4;
        final red = pixels.getUint8(offset);
        final green = pixels.getUint8(offset + 1);
        final blue = pixels.getUint8(offset + 2);
        final alpha = pixels.getUint8(offset + 3);
        if (alpha > 0) {
          left = x < left ? x : left;
          right = x > right ? x : right;
        }
        if (red > 200 && green < 130 && blue < 150 && alpha > 0) {
          pinkPixels++;
        }
      }
    }

    expect(image.width, 200);
    expect(right - left, greaterThan(150));
    expect(pinkPixels, greaterThan(0));
    image.dispose();
    codec.dispose();
  });

  test(
    'keeps the original viewBox when the path inherits a transform',
    () async {
      const sourceSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
  <g transform="translate(-175,-1696)">
    <path d="M 180 1700 L 220 1700" style="stroke: black"/>
  </g>
</svg>
''';
      const csv = 'time,voltage\n0,0\n1,1\n2,0';
      final transformed = EcgProcessor.transform(
        svgXml: sourceSvg,
        csvText: csv,
        amplitude: 5,
      );
      final styled = EcgProcessor.styleSvg(
        svgXml: transformed,
        strokeColor: '#E55261',
        strokeWidth: 4,
      );
      final root = XmlDocument.parse(styled).rootElement;

      expect(root.getAttribute('viewBox'), '0 0 100 100');
      expect(root.getAttribute('width'), '100');
      expect(root.getAttribute('height'), '100');

      final png = await svgToPng(styled, maxDimension: 200);
      final codec = await ui.instantiateImageCodec(png);
      final image = (await codec.getNextFrame()).image;
      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      var visiblePixels = 0;
      for (var offset = 3; offset < pixels.lengthInBytes; offset += 4) {
        if (pixels.getUint8(offset) > 0) visiblePixels++;
      }

      expect(visiblePixels, greaterThan(0));
      image.dispose();
      codec.dispose();
    },
  );
}
