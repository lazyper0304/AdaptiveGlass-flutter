import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/constants/theme_constants.dart';

/// 自定义 GlassButton 组件
class AppGlassButton extends StatelessWidget {
  const AppGlassButton({
    super.key,
    required this.onTap,
    this.icon,
    this.label,
    this.width = 44,
    this.height = 44,
    this.iconSize = 22,
    this.quality = GlassQuality.standard,
    this.enabled = true,
    this.glowColor,
  });

  final VoidCallback onTap;
  final Widget? icon;
  final String? label;
  final double width;
  final double height;
  final double iconSize;
  final GlassQuality quality;
  final bool enabled;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? accentColorDark : accentColorLight;

    return GlassButton(
      icon: icon,
      onTap: enabled ? onTap : null,
      enabled: enabled,
      width: width,
      height: height,
      iconSize: iconSize,
      label: label ?? '',
      quality: quality,
      glowColor: glowColor ?? accent.withValues(alpha: 0.34),
    );
  }
}
