import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../models/frame_template.dart';
import '../models/home_template_data.dart';
import '../painters/home_painters.dart';

class TemplateTile extends StatelessWidget {
  const TemplateTile({super.key, required this.data, required this.onTap});

  final TemplateData data;
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
                child: switch (data.template) {
                  FrameTemplate.classic => _ClassicTemplatePreview(
                    variant: data.variant,
                  ),
                  FrameTemplate.colorBorder =>
                    const _ColorBorderTemplatePreview(),
                  FrameTemplate.watermarkBorder =>
                    const _WatermarkBorderTemplatePreview(),
                  FrameTemplate.colorWalk =>
                    const _ColorWalkTemplatePreview(),
                },
              ),
            ),
            const SizedBox(height: 14),
            Hero(
              tag: data.template.heroTag,
              child: Material(
                type: MaterialType.transparency,
                child: Text(
                  data.title,
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

class _ClassicTemplatePreview extends StatelessWidget {
  const _ClassicTemplatePreview({required this.variant});

  final int variant;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: PhotoScenePainter(variant: variant)),
        const Align(
          alignment: Alignment.bottomCenter,
          child: _CameraMetaStrip(),
        ),
      ],
    );
  }
}

class _ColorBorderTemplatePreview extends StatelessWidget {
  const _ColorBorderTemplatePreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8EEE8), Color(0xFFF5F7FB)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE9E3DD), width: 1.5),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF5F1EC),
                      ),
                      child: CustomPaint(
                        painter: PhotoScenePainter(variant: 7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _PalettePreviewDot(
                          color: Color(0xFFFF6B6B),
                          label: '255,107,107',
                        ),
                        _PalettePreviewDot(
                          color: Color(0xFFFFA94D),
                          label: '255,169,77',
                        ),
                        _PalettePreviewDot(
                          color: Color(0xFFFFE066),
                          label: '255,224,102',
                        ),
                        _PalettePreviewDot(
                          color: Color(0xFF69DB7C),
                          label: '105,219,124',
                        ),
                        _PalettePreviewDot(
                          color: Color(0xFF74C0FC),
                          label: '116,192,252',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WatermarkBorderTemplatePreview extends StatelessWidget {
  const _WatermarkBorderTemplatePreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0E8DE), Color(0xFFF7F8FB)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: CustomPaint(painter: PhotoScenePainter(variant: 5)),
                ),
              ),
              const _WatermarkFooterPreview(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorWalkTemplatePreview extends StatelessWidget {
  const _ColorWalkTemplatePreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF8EC5FC),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ColorPreviewDot(color: Color(0xFFFF6B6B), selected: false),
                      _ColorPreviewDot(color: Color(0xFFFFA94D), selected: true),
                      _ColorPreviewDot(color: Color(0xFFFFE066), selected: false),
                      _ColorPreviewDot(color: Color(0xFF69DB7C), selected: false),
                      _ColorPreviewDot(color: Color(0xFF74C0FC), selected: false),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                color: Colors.white,
              ),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Color(0xFFF5F1EC),
                  ),
                  child: CustomPaint(painter: PhotoScenePainter(variant: 6)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorPreviewDot extends StatelessWidget {
  const _ColorPreviewDot({required this.color, required this.selected});

  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: selected ? 20 : 18,
          height: selected ? 20 : 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(color: Colors.white, width: 3)
                : Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }
}

class _PalettePreviewDot extends StatelessWidget {
  const _PalettePreviewDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7F746B),
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CameraMetaStrip extends StatelessWidget {
  const _CameraMetaStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white,
      child: const Row(
        children: [
          Text(
            'Canon',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '55mm  f/1.4  1/160s  ISO320',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WatermarkFooterPreview extends StatelessWidget {
  const _WatermarkFooterPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x14000000))),
      ),
      child: const Row(
        children: [
          Text(
            'SONY',
            style: TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sony A7R V',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ISO 200   f/2.8   1/125s   35mm',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF6A6A6A),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
