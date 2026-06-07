import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/constants/theme_constants.dart';

/// 自定义 GlassSlider 组件
class AppGlassSlider extends StatelessWidget {
  const AppGlassSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.quality = GlassQuality.standard,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final GlassQuality quality;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? accentColorDark : accentColorLight;

    return GlassSlider(
      value: value,
      min: min,
      max: max,
      onChanged: onChanged,
      activeColor: activeColor ?? accent,
      inactiveColor:
          inactiveColor ?? colors.onSurface.withValues(alpha: 0.16),
      thumbColor: thumbColor ?? colors.surface,
      quality: quality,
    );
  }
}
