import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'picked_file.dart';

Future<List<PickedFile>?> selectFiles({
  required List<String> extensions,
  required bool allowMultiple,
}) {
  final completer = Completer<List<PickedFile>?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = extensions.map((extension) => '.$extension').join(',')
    ..multiple = allowMultiple
    ..style.display = 'none';
  late JSFunction focusHandler;

  void removeInput() {
    web.window.removeEventListener('focus', focusHandler);
    input.remove();
  }

  void onFocus(web.Event event) {
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!completer.isCompleted && (input.files?.length ?? 0) == 0) {
        completer.complete(null);
        removeInput();
      }
    });
  }

  focusHandler = onFocus.toJS;

  void onCancel(web.Event event) {
    if (!completer.isCompleted) completer.complete(null);
    removeInput();
  }

  void onChange(web.Event event) async {
    final browserFiles = input.files;
    if (browserFiles == null || browserFiles.length == 0) {
      if (!completer.isCompleted) completer.complete(null);
      removeInput();
      return;
    }

    try {
      final files = <PickedFile>[];
      for (var index = 0; index < browserFiles.length; index++) {
        final file = browserFiles.item(index);
        if (file == null) continue;
        files.add(PickedFile(name: file.name, bytes: await _readBytes(file)));
      }
      if (!completer.isCompleted) completer.complete(files);
    } catch (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    } finally {
      removeInput();
    }
  }

  input.addEventListener('change', onChange.toJS);
  input.addEventListener('cancel', onCancel.toJS);
  web.window.addEventListener('focus', focusHandler);
  web.document.body!.appendChild(input);
  input.click();
  return completer.future;
}

Future<Uint8List> _readBytes(web.File file) {
  final completer = Completer<Uint8List>();
  final reader = web.FileReader();
  reader.addEventListener(
    'loadend',
    (web.Event event) {
      final result = reader.result;
      if (result == null) {
        completer.completeError(
          StateError('Não foi possível ler o arquivo "${file.name}".'),
        );
        return;
      }
      try {
        completer.complete((result as JSArrayBuffer).toDart.asUint8List());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    }.toJS,
  );
  reader.readAsArrayBuffer(file);
  return completer.future;
}
