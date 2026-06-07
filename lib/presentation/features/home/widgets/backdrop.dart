import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// 主页背景
class HomeBackdrop extends StatelessWidget {
  const HomeBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScope(
      background: const Center(
        child: Icon(
          Icons.camera_alt_outlined,
          size: 200,
          color: Color(0xFF79D6FF),
          semanticLabel: 'AdaptiveGlass',
        ),
      ),
      content: const SizedBox.shrink(),
    );
  }
}
