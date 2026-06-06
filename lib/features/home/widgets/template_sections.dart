import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../models/frame_template.dart';
import '../models/home_template_data.dart';

class TemplateTile extends StatelessWidget {
  const TemplateTile({super.key, required this.data, required this.onTap});

  final TemplateData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      shape: const LiquidRoundedSuperellipse(borderRadius: 24),
      quality: GlassQuality.standard,
      settings: LiquidGlassSettings(
        blur: 10,
        thickness: isDark ? 28 : 24,
        glassColor: isDark ? const Color(0x421C2026) : const Color(0xB5FFFFFF),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: data.template.heroTag,
              child: Material(
                type: MaterialType.transparency,
                child: Text(
                  data.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: 'SmileySans',
                    color: colors.onSurface.withValues(alpha: 0.92),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.64),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
