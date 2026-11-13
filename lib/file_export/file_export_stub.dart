import 'dart:typed_data';

Future<bool> saveExport({
  required String fileName,
  required String extension,
  required String mimeType,
  required Uint8List bytes,
}) {
  throw UnsupportedError('A exportação não é suportada nesta plataforma.');
}
