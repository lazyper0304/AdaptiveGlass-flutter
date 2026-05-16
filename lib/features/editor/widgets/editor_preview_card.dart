import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

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
    this.sourceBytes,
    this.sourceBytesThumb,
  });

  final PreviewCompositeOutput? preview;
  final ProcessingSettings settings;
  final ExifSnapshot exif;
  final VoidCallback onTap;
  final Uint8List? sourceBytes;
  final Uint8List? sourceBytesThumb;

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
              child: sourceBytes == null
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
                  : _RealtimePreviewLayer(
                      preview: preview,
                      settings: settings,
                      exif: exif,
                      sourceBytes: sourceBytes!,
                      thumbBytes: sourceBytesThumb,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RealtimePreviewLayer extends StatefulWidget {
  const _RealtimePreviewLayer({
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
  State<_RealtimePreviewLayer> createState() => _RealtimePreviewLayerState();
}

class _RealtimePreviewLayerState extends State<_RealtimePreviewLayer> {
  ui.Image? _sourceImage;
  bool _imagesReady = false;

  @override
  void initState() {
    super.initState();
    _loadSourceImage();
  }

  Future<void> _loadSourceImage() async {
    try {
      final codec = await ui.instantiateImageCodec(
        widget.sourceBytes,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _sourceImage = frame.image;
          _imagesReady = true;
        });
      }
    } catch (e) {
      // 忽略错误
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_imagesReady || _sourceImage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildFullRealtimePreview();
  }

  Widget _buildFullRealtimePreview() {
    final targetRatio = _calculateTargetRatio();

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: AspectRatio(
        aspectRatio: targetRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final targetWidth = constraints.maxWidth;
            final targetHeight = targetWidth / targetRatio;
            
            final layout = _calculateLayout(
              targetWidth, targetHeight);

            final scale = 1.0;
            final borderWidth = widget.settings.borderStyle == BorderStyleOption.none
                ? 0.0
                : (widget.settings.borderWidth * scale).clamp(1.0, 20.0);
            final borderRadius =
                widget.settings.borderStyle == BorderStyleOption.rounded
                    ? (widget.settings.cornerRadius * scale).clamp(0.0, 50.0)
                    : 0.0;
            final shadowBlur =
                (widget.settings.shadowSize * scale).clamp(0.0, 30.0);
            final radius = BorderRadius.circular(borderRadius);

            return RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildRealtimeBlurBackground(layout, scale),
                  Positioned(
                    left: layout.contentX * scale,
                    top: layout.contentY * scale,
                    width: layout.contentWidth * scale,
                    height: layout.contentHeight * scale,
                    child: _buildForegroundWithBorder(
                      scale,
                      radius,
                      borderWidth,
                      shadowBlur,
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

  double _calculateTargetRatio() {
    if (_sourceImage == null) return 16 / 9;

    final preset = widget.settings.targetRatio;
    
    if (preset == RatioPreset.original) {
      return _sourceImage!.width / _sourceImage!.height;
    }

    final dimensions = preset.dimensions;
    if (dimensions != null) {
      return dimensions.width / dimensions.height;
    }
    
    return _sourceImage!.width / _sourceImage!.height;
  }

  LayoutInfo _calculateLayout(
    double targetWidth,
    double targetHeight,
  ) {
    if (_sourceImage == null) {
      return LayoutInfo(
        targetWidth: targetWidth.toInt(),
        targetHeight: targetHeight.toInt(),
        contentX: 0,
        contentY: 0,
        contentWidth: targetWidth.toInt(),
        contentHeight: targetHeight.toInt(),
      );
    }

    final imageW = _sourceImage!.width.toDouble();
    final imageH = _sourceImage!.height.toDouble();
    final imageRatio = imageW / imageH;
    final targetRatio = targetWidth / targetHeight;

    double contentW, contentH;
    if (imageRatio > targetRatio) {
      // 图片更宽
      contentW = targetWidth;
      contentH = targetWidth / imageRatio;
    } else {
      // 图片更高或相等
      contentH = targetHeight;
      contentW = targetHeight * imageRatio;
    }

    // 应用内容缩放
    final contentScale = widget.settings.contentScale / 100.0;
    contentW *= contentScale;
    contentH *= contentScale;

    // 居中
    final contentX = (targetWidth - contentW) / 2;
    final contentY = (targetHeight - contentH) / 2;

    return LayoutInfo(
      targetWidth: targetWidth.toInt(),
      targetHeight: targetHeight.toInt(),
      contentX: contentX.toInt(),
      contentY: contentY.toInt(),
      contentWidth: contentW.toInt(),
      contentHeight: contentH.toInt(),
    );
  }

  Widget _buildRealtimeBlurBackground(LayoutInfo layout, double scale) {
    final blurRadius = widget.settings.blurRadius;
    final blurMode = widget.settings.blurMode;
    final blurBrightness = widget.settings.blurBrightness;

    if (_sourceImage == null) {
      return Container(color: Colors.grey[850]);
    }

    return _CanvasBlurBackground(
      sourceImage: _sourceImage!,
      blurRadius: blurRadius,
      blurMode: blurMode,
      blurBrightness: blurBrightness,
    );
  }

  Widget _buildForegroundWithBorder(
    double scale,
    BorderRadius radius,
    double borderWidth,
    double shadowBlur,
  ) {
    Widget imageWidget = RawImage(
      image: _sourceImage,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.low,
    );

    if (widget.settings.borderStyle == BorderStyleOption.rounded) {
      return Container(
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
        foregroundDecoration: borderWidth <= 0
            ? null
            : BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: _monoColor(widget.settings.borderColor),
                  width: borderWidth,
                ),
              ),
        child: ClipRRect(
          borderRadius: radius,
          child: imageWidget,
        ),
      );
    } else if (widget.settings.borderStyle == BorderStyleOption.thin) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          boxShadow: shadowBlur <= 0
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.42),
                    blurRadius: shadowBlur,
                  ),
                ],
        ),
        foregroundDecoration: borderWidth <= 0
            ? null
            : BoxDecoration(
                border: Border.all(
                  color: _monoColor(widget.settings.borderColor),
                  width: borderWidth,
                ),
              ),
        child: imageWidget,
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          boxShadow: shadowBlur <= 0
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.42),
                    blurRadius: shadowBlur,
                  ),
                ],
        ),
        child: imageWidget,
      );
    }
  }
}

class _CanvasBlurBackground extends StatefulWidget {
  const _CanvasBlurBackground({
    required this.sourceImage,
    required this.blurRadius,
    required this.blurMode,
    required this.blurBrightness,
  });

  final ui.Image sourceImage;
  final int blurRadius;
  final BlurModeOption blurMode;
  final int blurBrightness;

  @override
  State<_CanvasBlurBackground> createState() => _CanvasBlurBackgroundState();
}

class _CanvasBlurBackgroundState extends State<_CanvasBlurBackground> {
  ui.Image? _blurredImage;
  bool _isBlurring = false;

  @override
  void initState() {
    super.initState();
    _generateBlurredImage();
  }

  @override
  void didUpdateWidget(_CanvasBlurBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blurRadius != widget.blurRadius ||
        oldWidget.blurMode != widget.blurMode ||
        oldWidget.blurBrightness != widget.blurBrightness) {
      _generateBlurredImage();
    }
  }

  Future<void> _generateBlurredImage() async {
    if (_isBlurring) return;
    _isBlurring = true;

    try {
      final blurred = await _applyBlurInCanvas(
        widget.sourceImage,
        widget.blurRadius,
        widget.blurMode,
        widget.blurBrightness,
      );
      if (mounted && blurred != null) {
        setState(() {
          _blurredImage = blurred;
          _isBlurring = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBlurring = false);
      }
    }
  }

  Future<ui.Image?> _applyBlurInCanvas(
    ui.Image source,
    int blurRadius,
    BlurModeOption blurMode,
    int blurBrightness,
  ) async {
    final targetWidth = 160;
    final targetHeight = (source.height * (targetWidth / source.width)).round();
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    final src = Rect.fromLTWH(
      0, 0,
      source.width.toDouble(),
      source.height.toDouble(),
    );
    final dst = Rect.fromLTWH(
      0, 0,
      targetWidth.toDouble(),
      targetHeight.toDouble(),
    );
    
    canvas.drawImageRect(source, src, dst, Paint()..filterQuality = FilterQuality.low);
    
    final picture = recorder.endRecording();
    final thumbnail = await picture.toImage(targetWidth, targetHeight);
    
    final blurSigma = blurRadius * 0.05;
    if (blurSigma > 0) {
      final blurRecorder = ui.PictureRecorder();
      final blurCanvas = Canvas(blurRecorder);
      
      blurCanvas.drawImageRect(
        thumbnail,
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: blurSigma.clamp(0, 10),
            sigmaY: blurSigma.clamp(0, 10),
          ),
      );
      
      final blurPicture = blurRecorder.endRecording();
      final blurredThumbnail = await blurPicture.toImage(targetWidth, targetHeight);
      
      if (blurBrightness != 0 || blurMode != BlurModeOption.standard) {
        final finalRecorder = ui.PictureRecorder();
        final finalCanvas = Canvas(finalRecorder);
        
        finalCanvas.drawImage(blurredThumbnail, Offset.zero, Paint());
        
        if (blurMode == BlurModeOption.dark) {
          finalCanvas.drawRect(
            Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
            Paint()..color = Colors.black.withValues(alpha: 0.4),
          );
        } else if (blurMode == BlurModeOption.light) {
          finalCanvas.drawRect(
            Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
            Paint()..color = Colors.white.withValues(alpha: 0.3),
          );
        }
        
        if (blurBrightness > 0) {
          finalCanvas.drawRect(
            Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
            Paint()..color = Colors.white.withValues(alpha: blurBrightness * 0.01),
          );
        } else if (blurBrightness < 0) {
          finalCanvas.drawRect(
            Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
            Paint()..color = Colors.black.withValues(alpha: (-blurBrightness) * 0.01),
          );
        }
        
        final finalPicture = finalRecorder.endRecording();
        final result = await finalPicture.toImage(targetWidth, targetHeight);
        blurredThumbnail.dispose();
        return result;
      }
      
      return blurredThumbnail;
    }
    
    return thumbnail;
  }

  @override
  Widget build(BuildContext context) {
    if (_blurredImage == null) {
      return Container(color: Colors.grey[850]);
    }

    return CustomPaint(
      painter: _BlurredImagePainter(
        image: _blurredImage!,
      ),
      size: Size.infinite,
    );
  }

  @override
  void dispose() {
    _blurredImage?.dispose();
    super.dispose();
  }
}

class _BlurredImagePainter extends CustomPainter {
  const _BlurredImagePainter({required this.image});

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0, 0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _BlurredImagePainter oldDelegate) {
    return oldDelegate.image != image;
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
