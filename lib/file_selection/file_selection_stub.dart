import 'picked_file.dart';

Future<List<PickedFile>?> selectFiles({
  required List<String> extensions,
  required bool allowMultiple,
}) {
  throw UnsupportedError(
    'A seleção de arquivos não é suportada nesta plataforma.',
  );
}
