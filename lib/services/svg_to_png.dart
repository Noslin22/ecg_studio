import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';

Future<Uint8List> svgToPng(String svgXml, {int maxDimension = 2400}) async {
  if (maxDimension < 1) {
    throw ArgumentError.value(maxDimension, 'maxDimension', 'must be positive');
  }

  final pictureInfo = await vg.loadPicture(SvgStringLoader(svgXml), null);
  ui.Image? image;
  ui.Picture? rasterizedPicture;
  try {
    final sourceSize = pictureInfo.size;
    if (!sourceSize.width.isFinite ||
        !sourceSize.height.isFinite ||
        sourceSize.width <= 0 ||
        sourceSize.height <= 0) {
      throw FormatException('O SVG não possui dimensões válidas.');
    }

    final scale = math.min(
      maxDimension / sourceSize.width,
      maxDimension / sourceSize.height,
    );
    final width = (sourceSize.width * scale).round().clamp(1, maxDimension);
    final height = (sourceSize.height * scale).round().clamp(1, maxDimension);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..scale(scale);
    canvas.drawPicture(pictureInfo.picture);
    rasterizedPicture = recorder.endRecording();
    image = await rasterizedPicture.toImage(width, height);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) {
      throw StateError('Não foi possível converter o SVG para PNG.');
    }
    return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
  } finally {
    image?.dispose();
    rasterizedPicture?.dispose();
    pictureInfo.picture.dispose();
  }
}
