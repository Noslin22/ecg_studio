import 'file_selection_stub.dart'
    if (dart.library.io) 'file_selection_io.dart'
    if (dart.library.js_interop) 'file_selection_web.dart'
    as platform;
import 'picked_file.dart';

export 'picked_file.dart' show PickedFile;

Future<List<PickedFile>?> selectFiles({
  required List<String> extensions,
  required bool allowMultiple,
}) {
  return platform.selectFiles(
    extensions: extensions,
    allowMultiple: allowMultiple,
  );
}
