import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'picked_file.dart';

Future<List<PickedFile>?> selectFiles({
  required List<String> extensions,
  required bool allowMultiple,
}) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: extensions,
    allowMultiple: allowMultiple,
    withData: true,
    readSequential: true,
  );
  if (result == null) return null;

  final selectedFiles = <PickedFile>[];
  for (final file in result.files) {
    final bytes =
        file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) {
      throw StateError('Não foi possível ler o arquivo "${file.name}".');
    }
    selectedFiles.add(PickedFile(name: file.name, bytes: bytes));
  }
  return selectedFiles;
}
