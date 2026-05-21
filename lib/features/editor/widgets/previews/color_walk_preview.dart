import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../models/color_walk_settings.dart';
import '../../../../models/processing_settings.dart';
import '../../../../services/frame_processing_models.dart';
import '../../../../services/frame_renderers/color_walk_frame_renderer.dart';

class ColorWalkPreview extends StatelessWidget {
  const ColorWalkPreview({
    super.key,
    required this.image,
    required this.palette,
    required this.settings,
    required this.exif,
  });

  final ui.Image image;
  final List<PaletteSwatch> palette;
  final ProcessingSettings settings;
  final ExifSnapshot exif;

  @override
  Widget build(BuildContext context) {
    final colorWalkSettings = settings.colorWalk;
    final selectedColor = palette.isNotEmpty &&
            colorWalkSettings.selectedColorIndex >= 0 &&
            colorWalkSettings.selectedColorIndex < palette.length
        ? palette[colorWalkSettings.selectedColorIndex]
        : const PaletteSwatch(red: 236, green: 226, blue: 214);

    final metrics = calculateColorWalkLayoutMetrics(
      sourceWidth: image.width.toDouble(),
      sourceHeight: image.height.toDouble(),
      contentScale: colorWalkSettings.contentScale,
      position: colorWalkSettings.position,
    );

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: AspectRatio(
        aspectRatio: metrics.canvasWidth / metrics.canvasHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / metrics.canvasWidth;
            return _buildPreview(
              metrics,
              selectedColor,
              scale,
              colorWalkSettings,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPreview(
    ColorWalkLayoutMetrics metrics,
    PaletteSwatch selectedColor,
    double scale,
    ColorWalkSettings colorWalkSettings,
  ) {
    final paletteAreaWidth = metrics.paletteAreaWidth * scale;
    final paletteAreaHeight = metrics.paletteAreaHeight * scale;
    final paletteAreaOffset = Offset(
      metrics.paletteAreaOffset.dx * scale,
      metrics.paletteAreaOffset.dy * scale,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selectedColor.toColor(),
      ),
      child: Stack(
        children: [
          Positioned.fromRect(
            rect: Rect.fromLTWH(
              metrics.contentX * scale,
              metrics.contentY * scale,
              metrics.contentWidth * scale,
              metrics.contentHeight * scale,
            ),
            child: RawImage(
              image: image,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            ),
          ),
          _buildTextOverlay(
            paletteAreaOffset,
            paletteAreaWidth,
            paletteAreaHeight,
            colorWalkSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildTextOverlay(
    Offset paletteAreaOffset,
    double paletteAreaWidth,
    double paletteAreaHeight,
    ColorWalkSettings settings,
  ) {
    return Positioned(
      left: paletteAreaOffset.dx,
      top: paletteAreaOffset.dy,
      width: paletteAreaWidth,
      height: paletteAreaHeight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (settings.customText.isNotEmpty)
              Text(
                settings.customText,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: settings.customTextSize.toDouble(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (settings.showDateTime && exif.dateTimeOriginal.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  exif.dateTimeOriginal.split(' ').first,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: settings.dateTimeTextSize.toDouble(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
