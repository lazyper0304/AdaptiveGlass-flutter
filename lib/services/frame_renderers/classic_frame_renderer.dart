import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../models/processing_settings.dart';
import '../frame_processing_models.dart';

class ClassicFrameRenderer {
  Future<ProcessingOutput> process({
    required Uint8List sourceBytes,
    required ProcessingSettings settings,
    required ExifSnapshot exif,
    required RasterOutputFormat outputFormat,
    int? maxDimension,
    int jpegQuality = 95,
  }) async {
    if (maxDimension == null) {
      return _processGpuExport(
        sourceBytes: sourceBytes,
        settings: settings,
        exif: exif,
        outputFormat: outputFormat,
        jpegQuality: jpegQuality,
      );
    }

    final rasterResult = await compute(_processRasterTask, <String, Object?>{
      'bytes': sourceBytes,
      'settings': settings.toJson(),
      'max_dimension': maxDimension,
      'output_format': outputFormat.name,
      'jpeg_quality': jpegQuality,
    });

    final rasterBytes = rasterResult['bytes']! as Uint8List;
    final layoutInfo = LayoutInfo.fromJson(
      Map<String, dynamic>.from(rasterResult['layout']! as Map),
    );
    final renderScale = (rasterResult['render_scale']! as num).toDouble();
    final watermarkSettings = renderScale >= 0.999
        ? settings.watermark
        : _scaleWatermarkSettings(settings.watermark, renderScale);

    final outputBytes = settings.watermark.enabled
        ? await _applyWatermark(
            rasterBytes,
            watermarkSettings,
            exif,
            layoutInfo,
            outputFormat: outputFormat,
            jpegQuality: jpegQuality,
          )
        : rasterBytes;

    return ProcessingOutput(
      imageBytes: outputBytes,
      layoutInfo: layoutInfo,
      exif: exif,
    );
  }

  Future<PreviewCompositeOutput> processPreviewComposite(
    Uint8List sourceBytes,
    ProcessingSettings settings, {
    int maxDimension = 1600,
  }) async {
    final rasterResult =
        await compute(_processPreviewCompositeRasterTask, <String, Object?>{
          'bytes': sourceBytes,
          'settings': settings.toJson(),
          'max_dimension': maxDimension,
        });

    return PreviewCompositeOutput(
      compositeBytes: rasterResult['composite_bytes']! as Uint8List,
      backgroundBytes: rasterResult['background_bytes']! as Uint8List,
      foregroundBytes: rasterResult['foreground_bytes']! as Uint8List,
      layoutInfo: LayoutInfo.fromJson(
        Map<String, dynamic>.from(rasterResult['layout']! as Map),
      ),
      renderScale: (rasterResult['render_scale']! as num).toDouble(),
    );
  }

  Future<ProcessingOutput> _processGpuExport({
    required Uint8List sourceBytes,
    required ProcessingSettings settings,
    required ExifSnapshot exif,
    required RasterOutputFormat outputFormat,
    required int jpegQuality,
  }) async {
    final sourceImage = await _decodeUiImage(sourceBytes);
    final layoutInfo = calculateClassicLayoutInfo(
      sourceWidth: sourceImage.width,
      sourceHeight: sourceImage.height,
      settings: settings,
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    paintClassicFrameToCanvas(
      canvas: canvas,
      image: sourceImage,
      layoutInfo: layoutInfo,
      settings: settings,
      exif: exif,
    );

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(
      layoutInfo.targetWidth,
      layoutInfo.targetHeight,
    );
    final bytes = await _encodeUiImage(rendered, outputFormat, jpegQuality);

    sourceImage.dispose();
    rendered.dispose();
    picture.dispose();

    return ProcessingOutput(
      imageBytes: bytes,
      layoutInfo: layoutInfo,
      exif: exif,
    );
  }
}

void paintClassicFrameToCanvas({
  required Canvas canvas,
  required ui.Image image,
  required LayoutInfo layoutInfo,
  required ProcessingSettings settings,
  required ExifSnapshot exif,
}) {
  _paintClassicBackground(canvas, image, layoutInfo, settings);
  _paintClassicForeground(canvas, image, layoutInfo, settings);
  if (settings.watermark.enabled) {
    _paintClassicWatermark(canvas, settings.watermark, exif, layoutInfo);
  }
}

LayoutInfo calculateClassicLayoutInfo({
  required int sourceWidth,
  required int sourceHeight,
  required ProcessingSettings settings,
}) {
  final targetSize = _calculateTargetSize(
    sourceWidth,
    sourceHeight,
    settings.targetRatio,
  );
  final targetWidth = targetSize.$1;
  final targetHeight = targetSize.$2;
  final fitScale =
      math.min(targetWidth / sourceWidth, targetHeight / sourceHeight) *
      (settings.contentScale / 100);
  final contentWidth = math.max(1, (sourceWidth * fitScale).round());
  final contentHeight = math.max(1, (sourceHeight * fitScale).round());

  return LayoutInfo(
    targetWidth: targetWidth,
    targetHeight: targetHeight,
    contentX: (targetWidth - contentWidth) ~/ 2,
    contentY: (targetHeight - contentHeight) ~/ 2,
    contentWidth: contentWidth,
    contentHeight: contentHeight,
  );
}

Future<Map<String, Object?>> _processRasterTask(
  Map<String, Object?> input,
) async {
  final sourceBytes = input['bytes']! as Uint8List;
  final originalSettings = ProcessingSettings.fromJson(
    Map<String, dynamic>.from(input['settings']! as Map),
  );
  final maxDimension = (input['max_dimension'] as num?)?.round();
  final outputFormat =
      input['output_format'] as String? ?? RasterOutputFormat.png.name;
  final jpegQuality = (input['jpeg_quality'] as num?)?.round() ?? 95;

  final layers = _buildClassicRasterLayers(
    sourceBytes,
    originalSettings,
    maxDimension,
  );
  final finalImage = _renderClassicImage(
    background: layers.background.clone(),
    foreground: layers.foreground,
    layoutInfo: layers.layoutInfo,
    settings: layers.settings,
  );

  return <String, Object?>{
    'bytes': _encodeRaster(finalImage, outputFormat, jpegQuality),
    'layout': layers.layoutInfo.toJson(),
    'render_scale': layers.renderScale,
  };
}

Future<Map<String, Object?>> _processPreviewCompositeRasterTask(
  Map<String, Object?> input,
) async {
  final sourceBytes = input['bytes']! as Uint8List;
  final originalSettings = ProcessingSettings.fromJson(
    Map<String, dynamic>.from(input['settings']! as Map),
  );
  final maxDimension = (input['max_dimension'] as num?)?.round();
  final layers = _buildClassicRasterLayers(
    sourceBytes,
    originalSettings,
    maxDimension,
  );
  final composite = _renderClassicImage(
    background: layers.background.clone(),
    foreground: layers.foreground,
    layoutInfo: layers.layoutInfo,
    settings: layers.settings,
  );

  return <String, Object?>{
    'composite_bytes': _encodeRaster(
      composite,
      RasterOutputFormat.jpeg.name,
      88,
    ),
    'background_bytes': _encodeRaster(
      layers.background,
      RasterOutputFormat.jpeg.name,
      88,
    ),
    'foreground_bytes': img.encodePng(layers.foreground),
    'layout': layers.layoutInfo.toJson(),
    'render_scale': layers.renderScale,
  };
}

({
  img.Image background,
  img.Image foreground,
  LayoutInfo layoutInfo,
  double renderScale,
  ProcessingSettings settings,
})
_buildClassicRasterLayers(
  Uint8List sourceBytes,
  ProcessingSettings originalSettings,
  int? maxDimension,
) {
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) {
    throw StateError('无法解析图片文件。');
  }

  var source = img.bakeOrientation(decoded).convert(numChannels: 4);
  var renderScale = 1.0;
  if (maxDimension != null) {
    final resized = _downscaleForPreview(source, maxDimension);
    source = resized.image;
    renderScale = resized.scale;
  }

  final settings = renderScale >= 0.999
      ? originalSettings
      : _scaleSettingsForPreview(originalSettings, renderScale);
  final layoutInfo = calculateClassicLayoutInfo(
    sourceWidth: source.width,
    sourceHeight: source.height,
    settings: settings,
  );
  final background = _createBackground(
    source,
    layoutInfo.targetWidth,
    layoutInfo.targetHeight,
    settings,
  );
  final foreground = img
      .copyResize(
        source,
        width: layoutInfo.contentWidth,
        height: layoutInfo.contentHeight,
        interpolation: img.Interpolation.cubic,
      )
      .convert(numChannels: 4);

  return (
    background: background,
    foreground: foreground,
    layoutInfo: layoutInfo,
    renderScale: renderScale,
    settings: settings,
  );
}

img.Image _renderClassicImage({
  required img.Image background,
  required img.Image foreground,
  required LayoutInfo layoutInfo,
  required ProcessingSettings settings,
}) {
  var foregroundWithBorder = foreground;
  if (settings.borderStyle != BorderStyleOption.none) {
    foregroundWithBorder = _applyBorder(foregroundWithBorder, settings);
  }

  if (settings.shadowSize > 0) {
    final pad = settings.shadowSize * 3;
    final shadowLayer = img.Image(
      width: layoutInfo.contentWidth + pad * 2,
      height: layoutInfo.contentHeight + pad * 2,
      numChannels: 4,
    )..clear(img.ColorRgba8(0, 0, 0, 0));

    img.fillRect(
      shadowLayer,
      x1: pad,
      y1: pad,
      x2: pad + layoutInfo.contentWidth - 1,
      y2: pad + layoutInfo.contentHeight - 1,
      color: img.ColorRgba8(0, 0, 0, 180),
      radius: settings.borderStyle == BorderStyleOption.rounded
          ? settings.cornerRadius
          : 0,
    );
    img.gaussianBlur(shadowLayer, radius: settings.shadowSize);
    img.compositeImage(
      background,
      shadowLayer,
      dstX: layoutInfo.contentX - pad,
      dstY: layoutInfo.contentY - pad,
    );
  }

  img.compositeImage(
    background,
    foregroundWithBorder,
    dstX: layoutInfo.contentX,
    dstY: layoutInfo.contentY,
  );

  return background;
}

void _paintClassicBackground(
  Canvas canvas,
  ui.Image image,
  LayoutInfo layoutInfo,
  ProcessingSettings settings,
) {
  final dstRect = Rect.fromLTWH(
    0,
    0,
    layoutInfo.targetWidth.toDouble(),
    layoutInfo.targetHeight.toDouble(),
  );
  final srcRect = _coverSourceRect(
    image.width.toDouble(),
    image.height.toDouble(),
    dstRect.width,
    dstRect.height,
  );
  final brightnessFactor = math.max(0.0, 1.0 + (settings.blurBrightness / 100));

  final imagePaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..colorFilter = (brightnessFactor - 1.0).abs() > 0.001
        ? ui.ColorFilter.matrix(<double>[
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
          ])
        : null;
  final blurSigma = math.max(0.0, settings.blurRadius / 4);
  final layerPaint = Paint()
    ..imageFilter = blurSigma > 0
        ? ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma)
        : null;

  canvas.save();
  canvas.clipRect(dstRect);
  canvas.saveLayer(dstRect, layerPaint);
  canvas.drawImageRect(image, srcRect, dstRect, imagePaint);
  canvas.restore();
  canvas.restore();

  if (settings.blurMode == BlurModeOption.dark) {
    canvas.drawRect(
      dstRect,
      Paint()..color = Colors.black.withValues(alpha: 100 / 255),
    );
  } else if (settings.blurMode == BlurModeOption.light) {
    canvas.drawRect(
      dstRect,
      Paint()..color = Colors.white.withValues(alpha: 80 / 255),
    );
  }
}

void _paintClassicForeground(
  Canvas canvas,
  ui.Image image,
  LayoutInfo layoutInfo,
  ProcessingSettings settings,
) {
  final dstRect = Rect.fromLTWH(
    layoutInfo.contentX.toDouble(),
    layoutInfo.contentY.toDouble(),
    layoutInfo.contentWidth.toDouble(),
    layoutInfo.contentHeight.toDouble(),
  );
  final radius = settings.borderStyle == BorderStyleOption.rounded
      ? Radius.circular(settings.cornerRadius.toDouble())
      : Radius.zero;
  final shape = RRect.fromRectAndRadius(dstRect, radius);

  if (settings.shadowSize > 0) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.42)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        _boxShadowBlurToSigma(settings.shadowSize.toDouble()),
      );
    if (settings.borderStyle == BorderStyleOption.rounded) {
      canvas.drawRRect(shape, shadowPaint);
    } else {
      canvas.drawRect(dstRect, shadowPaint);
    }
  }

  final imagePaint = Paint()..filterQuality = FilterQuality.high;
  if (settings.borderStyle == BorderStyleOption.rounded) {
    canvas.save();
    canvas.clipRRect(shape);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dstRect,
      imagePaint,
    );
    canvas.restore();
  } else {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dstRect,
      imagePaint,
    );
  }

  if (settings.borderStyle != BorderStyleOption.none &&
      settings.borderWidth > 0) {
    final borderPaint = Paint()
      ..color = _monoColor(settings.borderColor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = settings.borderWidth.toDouble();
    if (settings.borderStyle == BorderStyleOption.rounded) {
      canvas.drawRRect(shape.deflate(settings.borderWidth / 2), borderPaint);
    } else {
      canvas.drawRect(dstRect.deflate(settings.borderWidth / 2), borderPaint);
    }
  }
}

void _paintClassicWatermark(
  Canvas canvas,
  WatermarkSettings settings,
  ExifSnapshot exif,
  LayoutInfo layoutInfo,
) {
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

  String modelText = '';
  String infoText = '';

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
      (layoutInfo.targetHeight -
              (layoutInfo.contentY + layoutInfo.contentHeight))
          .toDouble();
  final borderLeft = layoutInfo.contentX.toDouble();
  final borderRight =
      (layoutInfo.targetWidth - (layoutInfo.contentX + layoutInfo.contentWidth))
          .toDouble();

  var baseFontSize = settings.fontSize.toDouble();
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
    baseFontSize = math.max(12, baseFontSize);
  }

  baseFontSize = math.max(10, baseFontSize * settings.sizeScale);
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
  final x = position.dx + settings.customX.toDouble();
  final y = position.dy + settings.customY.toDouble();

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

Future<Uint8List> _applyWatermark(
  Uint8List rasterBytes,
  WatermarkSettings settings,
  ExifSnapshot exif,
  LayoutInfo layoutInfo, {
  required RasterOutputFormat outputFormat,
  required int jpegQuality,
}) async {
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

  String modelText = '';
  String infoText = '';

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
    return rasterBytes;
  }

  final baseImage = await _decodeUiImage(rasterBytes);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.drawImage(baseImage, Offset.zero, Paint());

  final borderTop = layoutInfo.contentY.toDouble();
  final borderBottom =
      (layoutInfo.targetHeight -
              (layoutInfo.contentY + layoutInfo.contentHeight))
          .toDouble();
  final borderLeft = layoutInfo.contentX.toDouble();
  final borderRight =
      (layoutInfo.targetWidth - (layoutInfo.contentX + layoutInfo.contentWidth))
          .toDouble();

  var baseFontSize = settings.fontSize.toDouble();
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
    baseFontSize = math.max(12, baseFontSize);
  }

  baseFontSize = math.max(10, baseFontSize * settings.sizeScale);
  final infoFontSize = math.max(10, baseFontSize * 0.7);
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
      fontSize: infoFontSize.toDouble(),
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
      fontSize: infoFontSize.toDouble(),
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
  final x = position.dx + settings.customX.toDouble();
  final y = position.dy + settings.customY.toDouble();

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

  final picture = recorder.endRecording();
  final rendered = await picture.toImage(
    layoutInfo.targetWidth,
    layoutInfo.targetHeight,
  );
  final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
  baseImage.dispose();
  rendered.dispose();
  picture.dispose();

  if (byteData == null) {
    throw StateError('无法渲染水印。');
  }

  final pngBytes = byteData.buffer.asUint8List();
  if (outputFormat == RasterOutputFormat.jpeg) {
    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) {
      throw StateError('预览图片编码失败。');
    }
    return img.encodeJpg(decoded, quality: jpegQuality);
  }

  return pngBytes;
}

Offset calculateClassicWatermarkPosition(
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

(int, int) _calculateTargetSize(
  int originalWidth,
  int originalHeight,
  RatioPreset ratio,
) {
  if (ratio == RatioPreset.original || ratio.dimensions == null) {
    return (originalWidth, originalHeight);
  }

  final dims = ratio.dimensions!;
  final targetHeightByWidth = (originalWidth * (dims.height / dims.width))
      .round();
  if (targetHeightByWidth >= originalHeight) {
    return (originalWidth, targetHeightByWidth);
  }

  final targetWidthByHeight = (originalHeight * (dims.width / dims.height))
      .round();
  return (targetWidthByHeight, originalHeight);
}

img.Image _createBackground(
  img.Image image,
  int targetWidth,
  int targetHeight,
  ProcessingSettings settings,
) {
  const downscaleFactor = 4;
  final smallWidth = math.max(1, targetWidth ~/ downscaleFactor);
  final smallHeight = math.max(1, targetHeight ~/ downscaleFactor);
  final scale = math.max(smallWidth / image.width, smallHeight / image.height);
  final resizedWidth = math.max(1, (image.width * scale).round());
  final resizedHeight = math.max(1, (image.height * scale).round());

  final bgSmall = img.copyResize(
    image,
    width: resizedWidth,
    height: resizedHeight,
    interpolation: img.Interpolation.linear,
  );
  final left = math.max(0, (resizedWidth - smallWidth) ~/ 2);
  final top = math.max(0, (resizedHeight - smallHeight) ~/ 2);
  final cropped = img
      .copyCrop(
        bgSmall,
        x: left,
        y: top,
        width: smallWidth,
        height: smallHeight,
      )
      .convert(numChannels: 4);

  final effectiveRadius = math.max(
    1,
    (settings.blurRadius / downscaleFactor).round(),
  );
  img.gaussianBlur(cropped, radius: effectiveRadius);

  if (settings.blurBrightness != 0) {
    final factor = math.max(0.0, 1.0 + (settings.blurBrightness / 100));
    for (final pixel in cropped) {
      pixel
        ..r = _clampToByte(pixel.r * factor)
        ..g = _clampToByte(pixel.g * factor)
        ..b = _clampToByte(pixel.b * factor);
    }
  }

  final bgFinal = img
      .copyResize(
        cropped,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.cubic,
      )
      .convert(numChannels: 4);

  if (settings.blurMode == BlurModeOption.dark) {
    img.fillRect(
      bgFinal,
      x1: 0,
      y1: 0,
      x2: targetWidth - 1,
      y2: targetHeight - 1,
      color: img.ColorRgba8(0, 0, 0, 100),
    );
  } else if (settings.blurMode == BlurModeOption.light) {
    img.fillRect(
      bgFinal,
      x1: 0,
      y1: 0,
      x2: targetWidth - 1,
      y2: targetHeight - 1,
      color: img.ColorRgba8(255, 255, 255, 80),
    );
  }

  return bgFinal;
}

img.Image _applyBorder(img.Image image, ProcessingSettings settings) {
  if (settings.borderStyle == BorderStyleOption.none) {
    return image;
  }

  final borderColor = settings.borderColor == MonoColor.white
      ? img.ColorRgba8(255, 255, 255, 255)
      : img.ColorRgba8(0, 0, 0, 255);

  if (settings.borderStyle == BorderStyleOption.thin) {
    final output = image.convert(numChannels: 4);
    if (settings.borderWidth > 0) {
      img.drawRect(
        output,
        x1: 0,
        y1: 0,
        x2: output.width - 1,
        y2: output.height - 1,
        color: borderColor,
        thickness: settings.borderWidth,
      );
    }
    return output;
  }

  final mask = img.Image(
    width: image.width,
    height: image.height,
    numChannels: 4,
  )..clear(img.ColorRgba8(0, 0, 0, 0));
  img.fillRect(
    mask,
    x1: 0,
    y1: 0,
    x2: image.width - 1,
    y2: image.height - 1,
    color: img.ColorRgba8(255, 255, 255, 255),
    radius: settings.cornerRadius,
  );

  final output = img.Image(
    width: image.width,
    height: image.height,
    numChannels: 4,
  )..clear(img.ColorRgba8(0, 0, 0, 0));
  img.compositeImage(output, image, mask: mask);

  if (settings.borderWidth > 0) {
    img.drawRect(
      output,
      x1: 0,
      y1: 0,
      x2: output.width - 1,
      y2: output.height - 1,
      color: borderColor,
      thickness: settings.borderWidth,
      radius: settings.cornerRadius,
    );
  }
  return output;
}

Uint8List _encodeRaster(img.Image image, String format, int jpegQuality) {
  return switch (format) {
    'jpeg' => img.encodeJpg(image, quality: jpegQuality),
    _ => img.encodePng(image),
  };
}

({img.Image image, double scale}) _downscaleForPreview(
  img.Image image,
  int maxDimension,
) {
  final longestEdge = math.max(image.width, image.height);
  if (longestEdge <= maxDimension) {
    return (image: image, scale: 1.0);
  }

  final scale = maxDimension / longestEdge;
  return (
    image: img.copyResize(
      image,
      width: math.max(1, (image.width * scale).round()),
      height: math.max(1, (image.height * scale).round()),
      interpolation: img.Interpolation.linear,
    ),
    scale: scale,
  );
}

ProcessingSettings _scaleSettingsForPreview(
  ProcessingSettings settings,
  double scale,
) {
  return settings.copyWith(
    blurRadius: _scalePositiveInt(settings.blurRadius, scale),
    borderWidth: _scalePositiveInt(settings.borderWidth, scale),
    cornerRadius: _scalePositiveInt(settings.cornerRadius, scale),
    shadowSize: _scalePositiveInt(settings.shadowSize, scale),
  );
}

WatermarkSettings _scaleWatermarkSettings(
  WatermarkSettings settings,
  double scale,
) {
  return settings.copyWith(
    fontSize: _scalePositiveInt(settings.fontSize, scale),
    customX: (settings.customX * scale).round(),
    customY: (settings.customY * scale).round(),
  );
}

int _scalePositiveInt(int value, double scale) {
  if (value <= 0) {
    return value;
  }
  return math.max(1, (value * scale).round());
}

int _clampToByte(num value) => value.clamp(0, 255).round();

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

TextPainter _buildTextPainter(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  );
  painter.layout();
  return painter;
}

Rect _coverSourceRect(
  double sourceWidth,
  double sourceHeight,
  double targetWidth,
  double targetHeight,
) {
  final sourceAspect = sourceWidth / sourceHeight;
  final targetAspect = targetWidth / targetHeight;

  if (sourceAspect > targetAspect) {
    final width = sourceHeight * targetAspect;
    return Rect.fromLTWH((sourceWidth - width) / 2, 0, width, sourceHeight);
  }

  final height = sourceWidth / targetAspect;
  return Rect.fromLTWH(0, (sourceHeight - height) / 2, sourceWidth, height);
}

Color _monoColor(MonoColor color) =>
    color == MonoColor.white ? Colors.white : Colors.black;

double _boxShadowBlurToSigma(double blurRadius) =>
    blurRadius > 0 ? blurRadius * 0.57735 + 0.5 : 0;

Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<Uint8List> _encodeUiImage(
  ui.Image image,
  RasterOutputFormat outputFormat,
  int jpegQuality,
) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('无法导出图像。');
  }

  final pngBytes = byteData.buffer.asUint8List();
  if (outputFormat == RasterOutputFormat.jpeg) {
    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) {
      throw StateError('无法编码 JPG 输出。');
    }
    return img.encodeJpg(decoded, quality: jpegQuality);
  }

  return pngBytes;
}
