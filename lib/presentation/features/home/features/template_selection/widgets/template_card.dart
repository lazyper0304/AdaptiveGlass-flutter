import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../core/constants/theme_constants.dart';
import '../../../../domain/entities/template.dart';

/// 模板卡片
class TemplateCard extends StatelessWidget {
  const TemplateCard({
    super.key,
    required this.template,
    required this.onTap,
  });

  final Template template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(12),
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
          children: [
            AspectRatio(
              aspectRatio: 1.95,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  color: Colors.grey.shade300,
                  child: Center(
                    child: Text(
                      template.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Hero(
              tag: template.id,
              child: Material(
                type: MaterialType.transparency,
                child: Text(
                  template.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'SmileySans',
                        color: colors.onSurface.withValues(alpha: 0.92),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              template.description,
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
