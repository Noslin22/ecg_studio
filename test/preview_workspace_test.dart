import 'package:ecg_studio/widgets/preview_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wide preview distributes cards within bounded height', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: _workspace(isWide: true))),
    );

    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('preview scrolls without flex errors when height is unbounded', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 800));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: _workspace(isWide: false)),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });
}

Widget _workspace({required bool isWide}) {
  return PreviewWorkspace(
    points: const [],
    strokeColor: const Color(0xFFE55261),
    strokeWidth: 2.5,
    originalSvg: '',
    originalSvgName: 'Nenhum SVG selecionado',
    resultSvg: '',
    amplitude: 12,
    onExport: () {},
    isWide: isWide,
  );
}
