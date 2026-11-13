import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ZoomablePreview extends StatefulWidget {
  const ZoomablePreview({required this.child, super.key});

  final Widget child;

  @override
  State<ZoomablePreview> createState() => _ZoomablePreviewState();
}

class _ZoomablePreviewState extends State<ZoomablePreview> {
  static const _minScale = 0.5;
  static const _maxScale = 6.0;
  final _transformationController = TransformationController();
  final _viewportKey = GlobalKey();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || event.kind != PointerDeviceKind.mouse) {
      return;
    }
    final renderObject = _viewportKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;

    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final factor = event.scrollDelta.dy < 0 ? 1.12 : 1 / 1.12;
    final nextScale = (currentScale * factor).clamp(_minScale, _maxScale);
    final scaleBy = nextScale / currentScale;
    final focalPoint = renderObject.globalToLocal(event.position);
    final zoom = Matrix4.identity()
      ..translateByDouble(focalPoint.dx, focalPoint.dy, 0, 1)
      ..scaleByDouble(scaleBy, scaleBy, 1, 1)
      ..translateByDouble(-focalPoint.dx, -focalPoint.dy, 0, 1);
    _transformationController.value = zoom * _transformationController.value;
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _PreviewGridPainter()),
            ),
            Listener(
              key: _viewportKey,
              onPointerSignal: _handlePointerSignal,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: _minScale,
                maxScale: _maxScale,
                boundaryMargin: const EdgeInsets.all(180),
                trackpadScrollCausesScale: true,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 1200,
                      height: 520,
                      child: Center(child: widget.child),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: Tooltip(
                message: 'Redefinir zoom',
                child: IconButton(
                  onPressed: _resetZoom,
                  icon: const Icon(Icons.fit_screen, size: 16),
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.8),
                    foregroundColor: const Color(0xFF444653),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PreviewGridPainter extends CustomPainter {
  const _PreviewGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFFAF8F6), BlendMode.src);
    final minor = Paint()
      ..color = const Color(0xFFEEDFE0)
      ..strokeWidth = 0.5;
    final major = Paint()
      ..color = const Color(0xFFE4C9CC)
      ..strokeWidth = 0.8;
    const spacing = 18.0;
    for (var x = 0.0, index = 0; x <= size.width; x += spacing, index++) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        index % 5 == 0 ? major : minor,
      );
    }
    for (var y = 0.0, index = 0; y <= size.height; y += spacing, index++) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        index % 5 == 0 ? major : minor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewGridPainter oldDelegate) => false;
}
