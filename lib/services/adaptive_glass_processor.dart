import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../models/processing_settings.dart';

class ProcessingOutput {
  const ProcessingOutput({
    required this.imageBytes,
    required this.layoutInfo,
    required this.exif,
  });

  final Uint8List imageBytes;
  final LayoutInfo layoutInfo;
  final ExifSnapshot exif;
}

class PreviewCompositeOutput {
  const PreviewCompositeOutput({
    required this.backgroundBytes,
    required this.foregroundBytes,
    required this.layoutInfo,
    required this.renderScale,
  });

  final Uint8List backgroundBytes;
  final Uint8List foregroundBytes;
  final LayoutInfo layoutInfo;
  final double renderScale;
}

class LayoutInfo {
  const LayoutInfo({
    required this.targetWidth,
    required this.targetHeight,
    required this.contentX,
    required this.contentY,
    required this.contentWidth,
    required this.contentHeight,
  });

  final int targetWidth;
  final int targetHeight;
  final int contentX;
  final int contentY;
  final int contentWidth;
  final int contentHeight;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'target_width': targetWidth,
      'target_height': targetHeight,
      'content_x': contentX,
      'content_y': contentY,
      'content_width': contentWidth,
      'content_height': contentHeight,
    };
  }

  factory LayoutInfo.fromJson(Map<String, dynamic> json) {
    return LayoutInfo(
      targetWidth: (json['target_width'] as num).round(),
      targetHeight: (json['target_height'] as num).round(),
      contentX: (json['content_x'] as num).round(),
      contentY: (json['content_y'] as num).round(),
      contentWidth: (json['content_width'] as num).round(),
      contentHeight: (json['content_height'] as num).round(),
    );
  }
}

class ExifSnapshot {
  const ExifSnapshot({
    this.make = '',
    this.model = '',
    this.iso = '',
    this.exposureTime = '',
    this.fNumber = '',
    this.focalLength = '',
  });

  final String make;
  final String model;
  final String iso;
  final String exposureTime;
  final String fNumber;
  final String focalLength;
}

class AdaptiveGlassProcessor {
  Future<ExifSnapshot> readExif(Uint8List sourceBytes) =>
      _readExif(sourceBytes);

  Future<ProcessingOutput> process(
    Uint8List sourceBytes,
    ProcessingSettings settings,
  ) {
    return processExport(sourceBytes, settings);
  }

  Future<ProcessingOutput> processPreview(
    Uint8List sourceBytes,
    ProcessingSettings settings, {
    ExifSnapshot exif = const ExifSnapshot(),
    int maxDimension = 1600,
  }) {
    return _process(
      sourceBytes,
      settings,
      exif: exif,
      maxDimension: maxDimension,
      outputFormat: _RasterOutputFormat.jpeg,
      jpegQuality: 88,
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
      backgroundBytes: rasterResult['background_bytes']! as Uint8List,
      foregroundBytes: rasterResult['foreground_bytes']! as Uint8List,
      layoutInfo: LayoutInfo.fromJson(
        Map<String, dynamic>.from(rasterResult['layout']! as Map),
      ),
      renderScale: (rasterResult['render_scale']! as num).toDouble(),
    );
  }

  Future<ProcessingOutput> processExport(
    Uint8List sourceBytes,
    ProcessingSettings settings, {
    ExifSnapshot? exif,
  }) async {
    return _process(
      sourceBytes,
      settings,
      exif: exif ?? await _readExif(sourceBytes),
      outputFormat: _RasterOutputFormat.png,
    );
  }

  Future<ProcessingOutput> _process(
    Uint8List sourceBytes,
    ProcessingSettings settings, {
    required ExifSnapshot exif,
    required _RasterOutputFormat outputFormat,
    int? maxDimension,
    int jpegQuality = 95,
  }) async {
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

  Uint8List encodeForExport(
    Uint8List previewBytes,
    String fileName,
    int quality,
  ) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      final decoded = img.decodeImage(previewBytes);
      if (decoded == null) {
        throw StateError('无法编码 JPG 输出。');
      }
      return img.encodeJpg(decoded, quality: quality);
    }

    if (lower.endsWith('.png')) {
      return previewBytes;
    }

    final decoded = img.decodeImage(previewBytes);
    if (decoded == null) {
      throw StateError('无法编码输出文件。');
    }
    return img.encodePng(decoded);
  }

  Future<ExifSnapshot> _readExif(Uint8List sourceBytes) async {
    try {
      final tags = await readExifFromBytes(sourceBytes);
      return ExifSnapshot(
        make: _extractPrintable(tags, const ['Image Make']),
        model: _extractPrintable(tags, const ['Image Model']),
        iso: _extractPrintable(tags, const [
          'EXIF ISOSpeedRatings',
          'EXIF PhotographicSensitivity',
        ]),
        exposureTime: _extractExposure(tags),
        fNumber: _extractRatioAsDecimal(tags, const ['EXIF FNumber']),
        focalLength: _extractRatioAsDecimal(tags, const ['EXIF FocalLength']),
      );
    } catch (_) {
      return const ExifSnapshot();
    }
  }

  Future<Uint8List> _applyWatermark(
    Uint8List rasterBytes,
    WatermarkSettings settings,
    ExifSnapshot exif,
    LayoutInfo layoutInfo, {
    required _RasterOutputFormat outputFormat,
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

    final ui.Image baseImage = await _decodeUiImage(rasterBytes);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    canvas.drawImage(baseImage, Offset.zero, paint);

    final borderTop = layoutInfo.contentY.toDouble();
    final borderBottom =
        (layoutInfo.targetHeight -
                (layoutInfo.contentY + layoutInfo.contentHeight))
            .toDouble();
    final borderLeft = layoutInfo.contentX.toDouble();
    final borderRight =
        (layoutInfo.targetWidth -
                (layoutInfo.contentX + layoutInfo.contentWidth))
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

    double x;
    double y;
    switch (settings.position) {
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

    switch (settings.position) {
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

    x += settings.customX.toDouble();
    y += settings.customY.toDouble();

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
    if (outputFormat == _RasterOutputFormat.jpeg) {
      final decoded = img.decodeImage(pngBytes);
      if (decoded == null) {
        throw StateError('预览图片编码失败。');
      }
      return img.encodeJpg(decoded, quality: jpegQuality);
    }

    return pngBytes;
  }
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
      input['output_format'] as String? ?? _RasterOutputFormat.png.name;
  final jpegQuality = (input['jpeg_quality'] as num?)?.round() ?? 95;

  final layers = _buildRasterLayers(
    sourceBytes,
    originalSettings,
    maxDimension,
  );
  final settings = layers.settings;
  final layoutInfo = layers.layoutInfo;
  var foreground = layers.foreground;

  if (settings.borderStyle != BorderStyleOption.none) {
    foreground = _applyBorder(foreground, settings);
  }

  final finalImage = layers.background.clone();

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
      finalImage,
      shadowLayer,
      dstX: layoutInfo.contentX - pad,
      dstY: layoutInfo.contentY - pad,
    );
  }

  img.compositeImage(
    finalImage,
    foreground,
    dstX: layoutInfo.contentX,
    dstY: layoutInfo.contentY,
  );

  return <String, Object?>{
    'bytes': _encodeRaster(finalImage, outputFormat, jpegQuality),
    'layout': layoutInfo.toJson(),
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
  final layers = _buildRasterLayers(
    sourceBytes,
    originalSettings,
    maxDimension,
  );

  return <String, Object?>{
    'background_bytes': _encodeRaster(
      layers.background,
      _RasterOutputFormat.jpeg.name,
      88,
    ),
    'foreground_bytes': img.encodePng(layers.foreground),
    'layout': layers.layoutInfo.toJson(),
    'render_scale': layers.renderScale,
  };
}

enum _RasterOutputFormat { png, jpeg }

({
  img.Image background,
  img.Image foreground,
  LayoutInfo layoutInfo,
  double renderScale,
  ProcessingSettings settings,
})
_buildRasterLayers(
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
  final targetSize = _calculateTargetSize(
    source.width,
    source.height,
    settings.targetRatio,
  );
  final targetWidth = targetSize.width;
  final targetHeight = targetSize.height;

  final background = _createBackground(
    source,
    targetWidth,
    targetHeight,
    settings,
  );
  final fitScale =
      math.min(targetWidth / source.width, targetHeight / source.height) *
      (settings.contentScale / 100);
  final contentWidth = math.max(1, (source.width * fitScale).round());
  final contentHeight = math.max(1, (source.height * fitScale).round());
  final foreground = img
      .copyResize(
        source,
        width: contentWidth,
        height: contentHeight,
        interpolation: img.Interpolation.cubic,
      )
      .convert(numChannels: 4);
  final contentX = (targetWidth - contentWidth) ~/ 2;
  final contentY = (targetHeight - contentHeight) ~/ 2;

  return (
    background: background,
    foreground: foreground,
    layoutInfo: LayoutInfo(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      contentX: contentX,
      contentY: contentY,
      contentWidth: contentWidth,
      contentHeight: contentHeight,
    ),
    renderScale: renderScale,
    settings: settings,
  );
}

({int width, int height}) _calculateTargetSize(
  int originalWidth,
  int originalHeight,
  RatioPreset ratio,
) {
  if (ratio == RatioPreset.original || ratio.dimensions == null) {
    return (width: originalWidth, height: originalHeight);
  }

  final dims = ratio.dimensions!;
  final targetHeightByWidth = (originalWidth * (dims.height / dims.width))
      .round();
  if (targetHeightByWidth >= originalHeight) {
    return (width: originalWidth, height: targetHeightByWidth);
  }

  final targetWidthByHeight = (originalHeight * (dims.width / dims.height))
      .round();
  return (width: targetWidthByHeight, height: originalHeight);
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

String _extractPrintable(Map<String, IfdTag> tags, List<String> keys) {
  final tag = _findTag(tags, keys);
  return tag?.printable.trim() ?? '';
}

String _extractExposure(Map<String, IfdTag> tags) {
  final tag = _findTag(tags, const ['EXIF ExposureTime']);
  if (tag == null) {
    return '';
  }

  final values = tag.values.toList();
  if (values.isNotEmpty && values.first is Ratio) {
    final ratio = values.first as Ratio;
    if (ratio.denominator == 0) {
      return '';
    }
    if (ratio.numerator >= ratio.denominator) {
      return _trimDecimal(ratio.toDouble());
    }
    return '${ratio.numerator}/${ratio.denominator}';
  }
  return tag.printable.trim();
}

String _extractRatioAsDecimal(Map<String, IfdTag> tags, List<String> keys) {
  final tag = _findTag(tags, keys);
  if (tag == null) {
    return '';
  }

  final values = tag.values.toList();
  if (values.isNotEmpty && values.first is Ratio) {
    final ratio = values.first as Ratio;
    if (ratio.denominator == 0) {
      return '';
    }
    return _trimDecimal(ratio.toDouble());
  }
  return tag.printable.trim();
}

IfdTag? _findTag(Map<String, IfdTag> tags, List<String> keys) {
  for (final key in keys) {
    final direct = tags[key];
    if (direct != null) {
      return direct;
    }
  }

  for (final entry in tags.entries) {
    final normalized = entry.key.toLowerCase();
    for (final key in keys) {
      if (normalized.endsWith(key.toLowerCase())) {
        return entry.value;
      }
    }
  }
  return null;
}

String _trimDecimal(double value) {
  final raw = value.toStringAsFixed(1);
  return raw.endsWith('.0') ? raw.substring(0, raw.length - 2) : raw;
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

TextPainter _buildTextPainter(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  );
  painter.layout();
  return painter;
}

Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}
