import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

/// 预设管理器
class PresetManagerWidget extends StatelessWidget {
  const PresetManagerWidget({
    super.key,
    required this.savePreset,
    required this.loadPreset,
  });

  final Future<void> Function() savePreset;
  final Future<void> Function() loadPreset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: savePreset,
          icon: const Icon(Icons.bookmark_add),
          label: const Text('保存预设'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: loadPreset,
          icon: const Icon(Icons.folder_open),
          label: const Text('加载预设'),
        ),
      ],
    );
  }
}
