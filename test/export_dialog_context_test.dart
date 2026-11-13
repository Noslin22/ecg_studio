import 'package:ecg_studio/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('screen context has MaterialLocalizations for export dialogs', (
    tester,
  ) async {
    await tester.pumpWidget(const MainApp());

    final screenContext = tester.element(find.byType(EcgDrawerScreen));
    expect(() => MaterialLocalizations.of(screenContext), returnsNormally);
    expect(tester.takeException(), isNull);
  });
}
