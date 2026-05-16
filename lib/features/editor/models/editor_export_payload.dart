import 'dart:typed_data';

class EditorExportPayload {
  const EditorExportPayload({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}
