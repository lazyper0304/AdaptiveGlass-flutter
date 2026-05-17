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
            final itemMetrics = calculateColorBorderPaletteItemMetrics(
              metrics: metrics,
              scale: scale,
            );

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
                          (itemMetrics.labelWidth / 2),
                      top: itemMetrics.circleTop,
                      width: itemMetrics.labelWidth,
                      child: Column(
                        children: [
                          Container(
                            width: itemMetrics.labelWidth,
                            alignment: Alignment.center,
                            child: Container(
                              width: itemMetrics.circleSize,
                              height: itemMetrics.circleSize,
                              decoration: BoxDecoration(
                                color: swatches[index].toColor(),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: itemMetrics.circleBorderWidth,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: itemMetrics.circleGap),
                          SizedBox(
                            width: itemMetrics.labelWidth,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                swatches[index].hexCode,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  color: const Color(0xFF6D6259),
                                  fontSize: itemMetrics.labelFontSize,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
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
