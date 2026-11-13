import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> saveExport({
  required String fileName,
  required String extension,
  required String mimeType,
  required Uint8List bytes,
}) async {
  final path = await FilePicker.saveFile(
    dialogTitle: 'Salvar imagem ECG',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: [extension],
    bytes: bytes,
  );
  return path != null;
}
