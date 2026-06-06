import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../models/frame_template.dart';
import '../../../models/processing_settings.dart';
import '../../../services/frame_processing_models.dart';
import '../../../shared/app_theme.dart';
import 'previews/classic_frame_preview.dart';
import 'previews/color_border_preview.dart';
import 'previews/color_walk_preview.dart';

class EditorPreviewCard extends StatefulWidget {
  const EditorPreviewCard({
    super.key,
    required this.template,
    required this.preview,
    required this.palette,
    required this.settings,
    required this.exif,
    required this.onTap,
    this.sourceBytes,
    this.sourceBytesThumb,
  });

  final FrameTemplate template;
  final PreviewCompositeOutput? preview;
  final List<PaletteSwatch> palette;
  final ProcessingSettings settings;
  final ExifSnapshot exif;
  final VoidCallback onTap;
  final Uint8List? sourceBytes;
  final Uint8List? sourceBytesThumb;

  @override
  State<EditorPreviewCard> createState() => _EditorPreviewCardState();
}

class _EditorPreviewCardState extends State<EditorPreviewCard> {
  ui.Image? _colorBorderImage;
  ui.Image? _colorWalkImage;

  @override
  void initState() {
    super.initState();
    _loadColorBorderImageIfNeeded();
    _loadColorWalkImageIfNeeded();
  }

  @override
  void didUpdateWidget(covariant EditorPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.sourceBytes, widget.sourceBytes) ||
        oldWidget.template != widget.template) {
      _disposeColorBorderImage();
      _disposeColorWalkImage();
      _loadColorBorderImageIfNeeded();
      _loadColorWalkImageIfNeeded();
    }
  }

  @override
  void dispose() {
    _disposeColorBorderImage();
    _disposeColorWalkImage();
    super.dispose();
  }

  Future<void> _loadColorBorderImageIfNeeded() async {
    if (widget.template != FrameTemplate.colorBorder ||
        widget.sourceBytes == null) {
      return;
    }

    try {
      final codec = await ui.instantiateImageCodec(
        widget.sourceBytes!,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _colorBorderImage = frame.image;
      });
    } catch (_) {}
  }

  void _disposeColorBorderImage() {
    _colorBorderImage?.dispose();
    _colorBorderImage = null;
  }

  Future<void> _loadColorWalkImageIfNeeded() async {
    if (widget.template != FrameTemplate.colorWalk ||
        widget.sourceBytes == null) {
      return;
    }

    try {
      final codec = await ui.instantiateImageCodec(
        widget.sourceBytes!,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _colorWalkImage = frame.image;
      });
    } catch (_) {}
  }

  void _disposeColorWalkImage() {
    _colorWalkImage?.dispose();
    _colorWalkImage = null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.accentColor;

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      height: double.infinity,
      shape: const LiquidRoundedSuperellipse(borderRadius: 28),
      quality: GlassQuality.standard,
      settings: LiquidGlassSettings(
        blur: 12,
        thickness: isDark ? 36 : 28,
        glassColor: isDark ? const Color(0x4A111820) : const Color(0xB8FFFFFF),
        lightIntensity: isDark ? 1.2 : 0.82,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: ColoredBox(
            color: isDark ? const Color(0x5511161E) : const Color(0x66FFFFFF),
            child: Center(child: _buildPreviewContent(colors, accent)),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewContent(ColorScheme colors, Color accent) {
    final sourceBytes = widget.sourceBytes;
    if (sourceBytes == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassButton(
            icon: const Icon(Icons.add_photo_alternate_rounded),
            onTap: widget.onTap,
            width: 70,
            height: 70,
            iconSize: 32,
            label: '导入图片',
            quality: GlassQuality.standard,
            glowColor: accent.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 18),
          Text(
            '点击导入图片',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.86),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    if (widget.template == FrameTemplate.colorBorder) {
      final image = _colorBorderImage;
      if (image != null) {
        return ColorBorderPreview(
          image: image,
          palette: widget.palette,
          settings: widget.settings,
        );
      }
      final thumbBytes = widget.sourceBytesThumb;
      if (thumbBytes != null) {
        return Center(
          child: Image.memory(
            thumbBytes,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.template == FrameTemplate.colorWalk) {
      final image = _colorWalkImage;
      if (image != null) {
        return ColorWalkPreview(
          image: image,
          palette: widget.palette,
          settings: widget.settings,
          exif: widget.exif,
        );
      }
      final thumbBytes = widget.sourceBytesThumb;
      if (thumbBytes != null) {
        return Center(
          child: Image.memory(
            thumbBytes,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return ClassicFramePreview(
      preview: widget.preview,
      settings: widget.settings,
      exif: widget.exif,
      sourceBytes: sourceBytes,
      thumbBytes: widget.sourceBytesThumb,
    );
  }
}
