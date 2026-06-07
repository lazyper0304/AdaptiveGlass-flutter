import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// 经典模板设置面板
class ClassicSettingsPanel extends StatelessWidget {
  const ClassicSettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final dynamic settings; // TODO: 使用实际的设置类型
  final ValueChanged<dynamic> onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      width: double.infinity,
      shape: const LiquidRoundedSuperellipse(borderRadius: 28),
      quality: GlassQuality.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('经典模板设置'),
          // TODO: 添加实际的设置项
        ],
      ),
    );
  }
}
