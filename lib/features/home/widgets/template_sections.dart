import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/home_template_data.dart';
import '../painters/home_painters.dart';

class TemplateTile extends StatelessWidget {
  const TemplateTile({
    super.key,
    required this.data,
    required this.onTap,
    this.compactMeta = false,
  });

  final TemplateData data;
  final VoidCallback onTap;
  final bool compactMeta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(10),
      shape: const LiquidRoundedSuperellipse(borderRadius: 20),
      quality: GlassQuality.standard,
      settings: LiquidGlassSettings(
        blur: 10,
        thickness: isDark ? 28 : 24,
        glassColor: isDark
            ? const Color(0x421C2026)
            : const Color(0xB5FFFFFF),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AspectRatio(
              aspectRatio: compactMeta ? 1.22 : 1.52,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: PhotoScenePainter(variant: data.variant),
                    ),
                    if (data.variant >= 3)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _CameraMetaStrip(compact: compactMeta),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Hero(
                tag: 'editor-title-${data.title}',
                child: Material(
                  type: MaterialType.transparency,
                  child: Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'SmileySans',
                      color: colors.onSurface.withValues(alpha: 0.9),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraMetaStrip extends StatelessWidget {
  const _CameraMetaStrip({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 34 : 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            compact ? 'Leica' : 'Canon',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.78),
              fontSize: compact ? 8 : 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              compact ? '85MM F1.8 ISO600 1/60s' : '55mm F14 1/160s ISO320',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.72),
                fontSize: compact ? 7 : 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
