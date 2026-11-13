import 'dart:typed_data';

import 'file_export_stub.dart'
    if (dart.library.io) 'file_export_io.dart'
    if (dart.library.js_interop) 'file_export_web.dart'
    as platform;

Future<bool> saveExport({
  required String fileName,
  required String extension,
  required String mimeType,
  required Uint8List bytes,
}) {
  return platform.saveExport(
    fileName: fileName,
    extension: extension,
    mimeType: mimeType,
    bytes: bytes,
  );
}
