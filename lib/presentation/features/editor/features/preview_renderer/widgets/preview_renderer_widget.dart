import 'package:flutter/material.dart';

/// 预览渲染器组件
class PreviewRendererWidget extends StatelessWidget {
  const PreviewRendererWidget({
    super.key,
    required this.image,
    required this.settings,
    this.onSettingsChanged,
  });

  final Uint8List image;
  final dynamic settings; // TODO: 使用实际的设置类型
  final ValueChanged<dynamic>? onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    // TODO: 实现实际的预览渲染逻辑
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.preview,
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            const Text(
              '预览区域',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
