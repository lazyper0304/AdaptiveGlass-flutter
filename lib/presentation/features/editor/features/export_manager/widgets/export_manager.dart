import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

/// 导出管理器
class ExportManagerWidget extends StatelessWidget {
  const ExportManagerWidget({
    super.key,
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;

  Future<void> _saveFile() async {
    final target = await FilePicker.saveFile(
      dialogTitle: '导出图片',
      fileName: fileName,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
      bytes: bytes,
    );

    if (!mounted) return;
    // TODO: 处理保存结果
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _saveFile,
          icon: const Icon(Icons.save),
          label: const Text('保存'),
        ),
      ],
    );
  }
}
