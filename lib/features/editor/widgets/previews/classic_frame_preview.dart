import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../models/processing_settings.dart';
import '../../../../services/frame_processing_models.dart';
import '../../../../services/frame_renderers/classic_frame_renderer.dart';

class ClassicFramePreview extends StatefulWidget {
  const ClassicFramePreview({
    super.key,
    required this.preview,
    required this.settings,
    required this.exif,
    required this.sourceBytes,
    this.thumbBytes,
  });

  final PreviewCompositeOutput? preview;
  final ProcessingSettings settings;
  final ExifSnapshot exif;
  final Uint8List sourceBytes;
  final Uint8List? thumbBytes;

  @override
  State<ClassicFramePreview> createState() => _ClassicFramePreviewState();
}

class _ClassicFramePreviewState extends State<ClassicFramePreview> {
  ui.Image? _sourceImage;

  @override
  void initState() {
    super.initState();
    _loadSourceImage();
  }

  @override
  void didUpdateWidget(covariant ClassicFramePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.sourceBytes, widget.sourceBytes)) {
      _disposeSourceImage();
      _loadSourceImage();
    }
  }

  Future<void> _loadSourceImage() async {
    try {
      final codec = await ui.instantiateImageCodec(
        widget.sourceBytes,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        _sourceImage = frame.image;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposeSourceImage();
    super.dispose();
  }

  void _disposeSourceImage() {
    _sourceImage?.dispose();
    _sourceImage = null;
  }

  @override
  Widget build(BuildContext context) {
    final sourceImage = _sourceImage;
    if (sourceImage == null) {
      final thumbBytes = widget.thumbBytes;
      if (thumbBytes != null) {
        return Center(
          child: Image.memory(
            thumbBytes,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        );
      }
      final preview = widget.preview;
      if (preview != null) {
        return Center(
          child: Image.memory(
            preview.compositeBytes,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final layout = calculateClassicLayoutInfo(
      sourceWidth: sourceImage.width,
      sourceHeight: sourceImage.height,
      settings: widget.settings,
    );

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: AspectRatio(
        aspectRatio: layout.targetWidth / layout.targetHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewScale = constraints.maxWidth / layout.targetWidth;
            final borderWidth =
                widget.settings.borderStyle == BorderStyleOption.none
                ? 0.0
                : widget.settings.borderWidth * viewScale;
            final borderRadius =
                widget.settings.borderStyle == BorderStyleOption.rounded
                ? widget.settings.cornerRadius * viewScale
                : 0.0;
            final shadowBlur = widget.settings.shadowSize * viewScale;
            final radius = BorderRadius.circular(borderRadius);

            return RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _RealtimeBackground(
                    image: sourceImage,
                    settings: widget.settings,
                  ),
                  Positioned(
                    left: layout.contentX * viewScale,
                    top: layout.contentY * viewScale,
                    width: layout.contentWidth * viewScale,
                    height: layout.contentHeight * viewScale,
                    child: _ForegroundImage(
                      image: sourceImage,
                      settings: widget.settings,
                      radius: radius,
                      borderWidth: borderWidth,
                      shadowBlur: shadowBlur,
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _WatermarkPreviewPainter(
                          settings: widget.settings.watermark,
                          exif: widget.exif,
                          layoutInfo: layout,
                          renderScale: 1.0,
                        ),
                      ),
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

class _ForegroundImage extends StatelessWidget {
  const _ForegroundImage({
    required this.image,
    required this.settings,
    required this.radius,
    required this.borderWidth,
    required this.shadowBlur,
  });

  final ui.Image image;
  final ProcessingSettings settings;
  final BorderRadius radius;
  final double borderWidth;
  final double shadowBlur;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = RawImage(
      image: image,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
    );

    final decoration = BoxDecoration(
      color: Colors.transparent,
      borderRadius:
          settings.borderStyle == BorderStyleOption.rounded ? radius : null,
      boxShadow: shadowBlur <= 0
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: shadowBlur,
              ),
            ],
    );

    final foregroundDecoration = borderWidth <= 0
        ? null
        : BoxDecoration(
            borderRadius:
                settings.borderStyle == BorderStyleOption.rounded
                ? radius
                : null,
            border: Border.all(
              color: _monoColor(settings.borderColor),
              width: borderWidth,
            ),
          );

    if (settings.borderStyle == BorderStyleOption.rounded) {
      imageWidget = ClipRRect(borderRadius: radius, child: imageWidget);
    }

    return Container(
      decoration: decoration,
      foregroundDecoration: foregroundDecoration,
      child: imageWidget,
    );
  }
}

class _RealtimeBackground extends StatelessWidget {
  const _RealtimeBackground({required this.image, required this.settings});

  final ui.Image image;
  final ProcessingSettings settings;

  @override
  Widget build(BuildContext context) {
    Widget child = SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: image.width.toDouble(),
          height: image.height.toDouble(),
          child: RawImage(
            image: image,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );

    final brightnessFactor = math.max(
      0.0,
      1.0 + (settings.blurBrightness / 100),
    );
    if ((brightnessFactor - 1.0).abs() > 0.001) {
      child = ColorFiltered(
        colorFilter: ColorFilter.matrix(<double>[
          brightnessFactor,
          0,
          0,
          0,
          0,
          0,
          brightnessFactor,
          0,
          0,
          0,
          0,
          0,
          brightnessFactor,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: child,
      );
    }

    final sigma = math.max(0.0, settings.blurRadius / 4);
    if (sigma > 0) {
      child = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (settings.blurMode == BlurModeOption.dark)
          ColoredBox(color: Colors.black.withValues(alpha: 100 / 255)),
        if (settings.blurMode == BlurModeOption.light)
          ColoredBox(color: Colors.white.withValues(alpha: 80 / 255)),
      ],
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

    final position = calculateClassicWatermarkPosition(
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

TextPainter _buildTextPainter(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  );
  painter.layout();
  return painter;
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
