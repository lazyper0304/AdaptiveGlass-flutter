import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../shared/app_theme.dart';

class EditorStatusBar extends StatelessWidget {
  const EditorStatusBar({
    super.key,
    required this.status,
    required this.processing,
  });

  final String status;
  final bool processing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.accentColor;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const LiquidRoundedSuperellipse(borderRadius: 18),
        quality: GlassQuality.standard,
        settings: LiquidGlassSettings(
          blur: 10,
          thickness: isDark ? 28 : 24,
          glassColor: isDark
              ? const Color(0x55121821)
              : const Color(0xB8FFFFFF),
          lightIntensity: isDark ? 1.2 : 0.82,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.86),
                ),
              ),
            ),
            if (processing) ...[
              const SizedBox(width: 12),
              GlassProgressIndicator.circular(size: 18, color: accent),
            ],
          ],
        ),
      ),
    );
  }
}
