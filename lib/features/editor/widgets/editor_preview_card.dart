import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../models/processing_settings.dart';
import '../../../services/adaptive_glass_processor.dart';

class EditorPreviewCard extends StatelessWidget {
  const EditorPreviewCard({
    super.key,
    required this.preview,
    required this.settings,
    required this.exif,
    required this.onTap,
  });

  final PreviewCompositeOutput? preview;
  final ProcessingSettings settings;
  final ExifSnapshot exif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFC7FF12) : const Color(0xFF238E54);

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
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: ColoredBox(
            color: isDark ? const Color(0x5511161E) : const Color(0x66FFFFFF),
            child: Center(
              child: preview == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlassButton(
                          icon: const Icon(Icons.add_photo_alternate_rounded),
                          onTap: onTap,
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.86),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    )
                  : RepaintBoundary(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4,
                        child: _LayeredPreview(
                          preview: preview!,
                          settings: settings,
                          exif: exif,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LayeredPreview extends StatelessWidget {
  const _LayeredPreview({
    required this.preview,
    required this.settings,
    required this.exif,
  });

  final PreviewCompositeOutput preview;
  final ProcessingSettings settings;
  final ExifSnapshot exif;

  @override
  Widget build(BuildContext context) {
    final layout = preview.layoutInfo;

    return Center(
      child: AspectRatio(
        aspectRatio: layout.targetWidth / layout.targetHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / layout.targetWidth;
            final borderWidth = settings.borderStyle == BorderStyleOption.none
                ? 0.0
                : _scaledPreviewValue(
                    settings.borderWidth,
                    preview.renderScale,
                    scale,
                  );
            final borderRadius =
                settings.borderStyle == BorderStyleOption.rounded
                ? _scaledPreviewValue(
                    settings.cornerRadius,
                    preview.renderScale,
                    scale,
                  )
                : 0.0;
            final shadowBlur = _scaledPreviewValue(
              settings.shadowSize,
              preview.renderScale,
              scale,
            );
            final radius = BorderRadius.circular(borderRadius);

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Image.memory(
                    preview.backgroundBytes,
                    gaplessPlayback: true,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                Positioned(
                  left: layout.contentX * scale,
                  top: layout.contentY * scale,
                  width: layout.contentWidth * scale,
                  height: layout.contentHeight * scale,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: radius,
                      boxShadow: shadowBlur <= 0
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.42),
                                blurRadius: shadowBlur,
                              ),
                            ],
                    ),
                    foregroundDecoration:
                        settings.borderStyle == BorderStyleOption.none ||
                            borderWidth <= 0
                        ? null
                        : BoxDecoration(
                            borderRadius: radius,
                            border: Border.all(
                              color: _monoColor(settings.borderColor),
                              width: borderWidth,
                            ),
                          ),
                    child: ClipRRect(
                      borderRadius: radius,
                      child: Image.memory(
                        preview.foregroundBytes,
                        gaplessPlayback: true,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _WatermarkPreviewPainter(
                        settings: settings.watermark,
                        exif: exif,
                        layoutInfo: layout,
                        renderScale: preview.renderScale,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WatermarkPreviewPainter extends CustomPainter {
  const _WatermarkPreviewPainter({
    required this.settings,
    required this.exif,
    required this.layoutInfo,
    required this.renderScale,
  });

  final WatermarkSettings settings;
  final ExifSnapshot exif;
  final LayoutInfo layoutInfo;
  final double renderScale;

  @override
  void paint(Canvas canvas, Size size) {
    if (!settings.enabled) {
      return;
    }

    final scale = size.width / layoutInfo.targetWidth;
    canvas.save();
    canvas.scale(scale);
    _paintInPreviewPixels(canvas);
    canvas.restore();
  }

  void _paintInPreviewPixels(Canvas canvas) {
    final templateText =
        settings.text.contains('{') && settings.text.contains('}')
        ? _formatTemplate(settings.text, exif)
        : settings.text;
    final exifModel = exif.model.isNotEmpty ? exif.model : exif.make;
    final infoParts = <String>[
      if (exif.iso.isNotEmpty) 'ISO${exif.iso}',
      if (exif.fNumber.isNotEmpty) 'f/${exif.fNumber}',
      if (exif.exposureTime.isNotEmpty) '${exif.exposureTime}s',
      if (exif.focalLength.isNotEmpty) '${exif.focalLength}mm',
    ];
    final exifInfo = infoParts.join('  ');

    var modelText = '';
    var infoText = '';
    switch (settings.textMode) {
      case WatermarkModeOption.replace:
        modelText = templateText.isNotEmpty ? templateText : '自定义文本';
        break;
      case WatermarkModeOption.fallback:
        if (exifModel.isNotEmpty) {
          modelText = exifModel;
          infoText = exifInfo;
        } else {
          modelText = templateText.isNotEmpty ? templateText : '无 EXIF 信息';
        }
        break;
      case WatermarkModeOption.append:
        if (exifModel.isNotEmpty) {
          modelText = exifModel;
          infoText = exifInfo;
          if (templateText.isNotEmpty) {
            infoText = infoText.isNotEmpty
                ? '$infoText  |  $templateText'
                : templateText;
          }
        } else {
          modelText = templateText;
        }
        break;
    }

    if (modelText.isEmpty && infoText.isEmpty) {
      return;
    }

    final borderTop = layoutInfo.contentY.toDouble();
    final borderBottom =
        layoutInfo.targetHeight -
        (layoutInfo.contentY + layoutInfo.contentHeight).toDouble();
    final borderLeft = layoutInfo.contentX.toDouble();
    final borderRight =
        layoutInfo.targetWidth -
        (layoutInfo.contentX + layoutInfo.contentWidth).toDouble();

    var baseFontSize = _scaledPreviewSetting(
      settings.fontSize,
      renderScale,
    ).toDouble();
    if (settings.autoSize) {
      final isVertical =
          settings.position.storageValue.contains('top') ||
          settings.position.storageValue.contains('bottom');
      if (settings.position == WatermarkPosition.manual) {
        baseFontSize = layoutInfo.targetWidth * 0.03;
      } else if (isVertical) {
        final refBorder = math.max(borderTop, borderBottom);
        baseFontSize = refBorder > 20
            ? refBorder * 0.35
            : layoutInfo.targetWidth * 0.03;
      } else {
        final refBorder = math.max(borderLeft, borderRight);
        if (settings.position.storageValue.contains('left') ||
            settings.position.storageValue.contains('right')) {
          baseFontSize = refBorder > 20
              ? math.min(refBorder * 0.15, layoutInfo.targetHeight * 0.05)
              : layoutInfo.targetWidth * 0.03;
        } else {
          baseFontSize = layoutInfo.targetWidth * 0.03;
        }
      }
      baseFontSize = math.max(12.0, baseFontSize);
    }

    baseFontSize = math.max(10.0, baseFontSize * settings.sizeScale);
    final infoFontSize = math.max(10.0, baseFontSize * 0.7);
    final textAlpha = settings.opacity / 100;
    final shadowAlpha = 0.5 * textAlpha;
    final textColor = settings.textColor == MonoColor.white
        ? Colors.white.withValues(alpha: textAlpha)
        : Colors.black.withValues(alpha: textAlpha);
    final shadowColor = settings.textColor == MonoColor.white
        ? Colors.black.withValues(alpha: shadowAlpha)
        : Colors.white.withValues(alpha: shadowAlpha);
    final fontFamily = settings.fontFamily == WatermarkFontFamily.smileySans
        ? 'SmileySans'
        : null;

    final modelPainter = _buildTextPainter(
      modelText,
      TextStyle(
        color: textColor,
        fontSize: baseFontSize,
        fontWeight: FontWeight.w700,
        fontFamily: fontFamily,
      ),
    );
    final infoPainter = _buildTextPainter(
      infoText,
      TextStyle(
        color: textColor,
        fontSize: infoFontSize,
        fontWeight: FontWeight.w500,
        fontFamily: fontFamily,
      ),
    );
    final modelShadowPainter = _buildTextPainter(
      modelText,
      TextStyle(
        color: shadowColor,
        fontSize: baseFontSize,
        fontWeight: FontWeight.w700,
        fontFamily: fontFamily,
      ),
    );
    final infoShadowPainter = _buildTextPainter(
      infoText,
      TextStyle(
        color: shadowColor,
        fontSize: infoFontSize,
        fontWeight: FontWeight.w500,
        fontFamily: fontFamily,
      ),
    );

    final gap = (modelText.isNotEmpty && infoText.isNotEmpty)
        ? baseFontSize * 0.8
        : 0.0;
    final totalWidth = modelPainter.width + gap + infoPainter.width;
    final maxHeight = math.max(modelPainter.height, infoPainter.height);

    final position = _watermarkPosition(
      settings.position,
      layoutInfo,
      borderTop,
      borderBottom,
      borderLeft,
      borderRight,
      totalWidth,
      maxHeight,
    );
    final x =
        position.dx + _scaledPreviewSetting(settings.customX, renderScale);
    final y =
        position.dy + _scaledPreviewSetting(settings.customY, renderScale);

    if (modelText.isNotEmpty) {
      final modelY = y + (maxHeight - modelPainter.height);
      modelShadowPainter.paint(canvas, Offset(x + 1, modelY + 1));
      modelPainter.paint(canvas, Offset(x, modelY));
    }

    if (infoText.isNotEmpty) {
      final infoX = x + modelPainter.width + gap;
      final infoY = y + (maxHeight - infoPainter.height);
      infoShadowPainter.paint(canvas, Offset(infoX + 1, infoY + 1));
      infoPainter.paint(canvas, Offset(infoX, infoY));
    }
  }

  @override
  bool shouldRepaint(covariant _WatermarkPreviewPainter oldDelegate) => true;
}

Offset _watermarkPosition(
  WatermarkPosition position,
  LayoutInfo layoutInfo,
  double borderTop,
  double borderBottom,
  double borderLeft,
  double borderRight,
  double totalWidth,
  double maxHeight,
) {
  double x;
  double y;
  switch (position) {
    case WatermarkPosition.topCenter:
    case WatermarkPosition.topLeft:
    case WatermarkPosition.topRight:
      y = borderTop > 20 ? (borderTop / 2) - (maxHeight / 2) : 20;
      break;
    case WatermarkPosition.bottomCenter:
    case WatermarkPosition.bottomLeft:
    case WatermarkPosition.bottomRight:
      if (borderBottom > 20) {
        final startY = layoutInfo.contentY + layoutInfo.contentHeight;
        y = startY + (borderBottom / 2) - (maxHeight / 2);
      } else {
        y = layoutInfo.targetHeight - maxHeight - 20;
      }
      break;
    case WatermarkPosition.center:
    case WatermarkPosition.centerLeft:
    case WatermarkPosition.centerRight:
    case WatermarkPosition.manual:
      y = (layoutInfo.targetHeight - maxHeight) / 2;
      break;
  }

  switch (position) {
    case WatermarkPosition.topLeft:
    case WatermarkPosition.bottomLeft:
      x = 20;
      break;
    case WatermarkPosition.topRight:
    case WatermarkPosition.bottomRight:
      x = layoutInfo.targetWidth - totalWidth - 20;
      break;
    case WatermarkPosition.centerLeft:
      x = borderLeft > 20 ? (borderLeft / 2) - (totalWidth / 2) : 20;
      break;
    case WatermarkPosition.centerRight:
      if (borderRight > 20) {
        final startX = layoutInfo.contentX + layoutInfo.contentWidth;
        x = startX + (borderRight / 2) - (totalWidth / 2);
      } else {
        x = layoutInfo.targetWidth - totalWidth - 20;
      }
      break;
    case WatermarkPosition.topCenter:
    case WatermarkPosition.bottomCenter:
    case WatermarkPosition.center:
    case WatermarkPosition.manual:
      x = (layoutInfo.targetWidth - totalWidth) / 2;
      break;
  }

  return Offset(x, y);
}

TextPainter _buildTextPainter(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  );
  painter.layout();
  return painter;
}

double _scaledPreviewValue(int value, double renderScale, double viewScale) {
  return _scaledPreviewSetting(value, renderScale) * viewScale;
}

int _scaledPreviewSetting(int value, double renderScale) {
  if (value == 0) {
    return 0;
  }

  final scaled = (value * renderScale).round();
  return value > 0 ? math.max(1, scaled) : scaled;
}

Color _monoColor(MonoColor color) {
  return color == MonoColor.white ? Colors.white : Colors.black;
}

String _formatTemplate(String template, ExifSnapshot exif) {
  return template
      .replaceAll('{Model}', exif.model)
      .replaceAll('{Make}', exif.make)
      .replaceAll('{ISO}', exif.iso.isNotEmpty ? 'ISO${exif.iso}' : '')
      .replaceAll(
        '{FNumber}',
        exif.fNumber.isNotEmpty ? 'f/${exif.fNumber}' : '',
      )
      .replaceAll(
        '{ExposureTime}',
        exif.exposureTime.isNotEmpty ? '${exif.exposureTime}s' : '',
      )
      .replaceAll(
        '{FocalLength}',
        exif.focalLength.isNotEmpty ? '${exif.focalLength}mm' : '',
      );
}
