import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../models/processing_settings.dart';
import '../../../../services/frame_processing_models.dart';
import '../../../../services/frame_renderers/color_border_frame_renderer.dart';

class ColorBorderPreview extends StatelessWidget {
  const ColorBorderPreview({
    super.key,
    required this.image,
    required this.palette,
    required this.settings,
  });

  final ui.Image image;
  final List<PaletteSwatch> palette;
  final ProcessingSettings settings;

  @override
  Widget build(BuildContext context) {
    final metrics = calculateColorBorderLayoutMetrics(
      sourceWidth: image.width.toDouble(),
      sourceHeight: image.height.toDouble(),
      contentScale: settings.contentScale,
    );
    final swatches = palette.isEmpty
        ? List<PaletteSwatch>.filled(
            5,
            const PaletteSwatch(red: 236, green: 226, blue: 214),
          )
        : palette;

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: AspectRatio(
        aspectRatio: metrics.canvasWidth / metrics.canvasHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / metrics.canvasWidth;
            final photoRect = Rect.fromLTWH(
              metrics.photoX * scale,
              metrics.photoY * scale,
              metrics.photoWidth * scale,
              metrics.photoHeight * scale,
            );
            final labelWidth = metrics.labelWidth * scale;
            final circleSize = math.min(
              labelWidth,
              metrics.circleRadius * 3.1 * scale,
            );
            final circleTop = metrics.circleCenterY * scale - (circleSize / 2);
            final labelFontSize = math.max(7.0, 10.5 * scale);

            return DecoratedBox(
              decoration: const BoxDecoration(color: Colors.white),
              child: Stack(
                children: [
                  Positioned.fromRect(
                    rect: photoRect,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 22 * scale,
                            offset: Offset(0, 8 * scale),
                          ),
                        ],
                      ),
                      child: RawImage(
                        image: image,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  for (var index = 0; index < swatches.length; index++)
                    Positioned(
                      left:
                          (metrics.circleCenters[index] * scale) -
                          (labelWidth / 2),
                      top: circleTop,
                      width: labelWidth,
                      child: Column(
                        children: [
                          Container(
                            width: labelWidth,
                            alignment: Alignment.center,
                            child: Container(
                              width: circleSize,
                              height: circleSize,
                              decoration: BoxDecoration(
                                color: swatches[index].toColor(),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: math.max(2, 4 * scale),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10 * scale),
                          SizedBox(
                            width: labelWidth,
                            child: Text(
                              swatches[index].hexCode,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                color: const Color(0xFF6D6259),
                                fontSize: labelFontSize,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
