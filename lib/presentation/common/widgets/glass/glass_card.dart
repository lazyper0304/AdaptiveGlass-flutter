import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/constants/theme_constants.dart';

/// 自定义 GlassCard 组件
class AppGlassCard extends StatelessWidget {
  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = ThemeConstants.borderRadius,
    this.quality = GlassQuality.standard,
    this.blur = ThemeConstants.glassBlur,
    this.thickness,
    this.glassColor,
    this.lightIntensity,
    this.shadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final GlassQuality quality;
  final double blur;
  final double? thickness;
  final Color? glassColor;
  final double? lightIntensity;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: padding,
      shape: LiquidRoundedSuperellipse(borderRadius: borderRadius),
      quality: quality,
      settings: LiquidGlassSettings(
        blur: blur,
        thickness: thickness ?? (isDark ? 36 : 28),
        glassColor: glassColor ?? (isDark ? glassColorDark : glassColorLight),
        lightIntensity: lightIntensity ?? (isDark ? 1.2 : 0.82),
      ),
      child: shadow != null
          ? Container(
              decoration: BoxDecoration(boxShadow: shadow),
              child: child,
            )
          : child,
    );
  }
}
