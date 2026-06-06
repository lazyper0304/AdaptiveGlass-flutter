import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../models/frame_template.dart';
import '../../models/processing_settings.dart';
import '../frame_processing_models.dart';
import 'classic_info_border_support.dart';
import 'renderer_utils.dart';
import 'watermark_renderer.dart';

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

    final outputBytes = _needsClassicDecorationPass(settings)
        ? await _applyClassicDecorations(
            rasterBytes: rasterBytes,
            settings: settings.copyWith(watermark: watermarkSettings),
            exif: exif,
            layoutInfo: layoutInfo,
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
    final layoutInfo = LayoutInfo.fromJson(
      Map<String, dynamic>.from(rasterResult['layout']! as Map),
    );
    final renderScale = (rasterResult['render_scale']! as num).toDouble();
    final scaledSettings = renderScale >= 0.999
        ? settings
        : _scaleSettingsForPreview(settings, renderScale).copyWith(
            watermark: _scaleWatermarkSettings(settings.watermark, renderScale),
          );
    final compositeBytes = _needsClassicDecorationPass(scaledSettings)
        ? await _applyClassicDecorations(
            rasterBytes: rasterResult['composite_bytes']! as Uint8List,
            settings: scaledSettings,
            exif: const ExifSnapshot(),
            layoutInfo: layoutInfo,
            outputFormat: RasterOutputFormat.jpeg,
            jpegQuality: 88,
          )
        : rasterResult['composite_bytes']! as Uint8List;

    return PreviewCompositeOutput(
      compositeBytes: compositeBytes,
      backgroundBytes: rasterResult['background_bytes']! as Uint8List,
      foregroundBytes: rasterResult['foreground_bytes']! as Uint8List,
      layoutInfo: layoutInfo,
      renderScale: renderScale,
    );
  }

  Future<ProcessingOutput> _processGpuExport({
    required Uint8List sourceBytes,
    required ProcessingSettings settings,
    required ExifSnapshot exif,
    required RasterOutputFormat outputFormat,
    required int jpegQuality,
  }) async {
    final sourceImage = await decodeUiImage(sourceBytes);
    final classicInfoBorderLogo = settings.classicInfoBorder.enabled
        ? await loadClassicInfoBorderLogo(
            resolveClassicInfoBorderLogoAsset(settings.classicInfoBorder, exif),
          )
        : null;
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
      classicInfoBorderLogo: classicInfoBorderLogo,
    );

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(
      layoutInfo.targetWidth,
      layoutInfo.targetHeight,
    );
    final bytes = await encodeUiImage(rendered, outputFormat, jpegQuality);

    sourceImage.dispose();
    rendered.dispose();
    picture.dispose();
    classicInfoBorderLogo?.dispose();

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
  ClassicInfoBorderLogo? classicInfoBorderLogo,
}) {
  _paintClassicBackground(canvas, image, layoutInfo, settings);
  _paintClassicForeground(canvas, image, layoutInfo, settings);
  paintClassicInfoBorder(
    canvas: canvas,
    layoutInfo: layoutInfo,
    settings: settings.classicInfoBorder,
    exif: exif,
    logo: classicInfoBorderLogo,
  );
  if (settings.watermark.enabled) {
    paintWatermark(canvas, settings.watermark, exif, layoutInfo);
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
  final infoPanelHeight = settings.classicInfoBorder.enabled
      ? calculateClassicInfoBorderMetrics(
          targetWidth: targetWidth,
          targetHeight: targetHeight,
          settings: settings.classicInfoBorder,
        ).footerHeight.round()
      : 0;
  final availableContentHeight = math.max(1, targetHeight - infoPanelHeight);
  final fitScale =
      math.min(
        targetWidth / sourceWidth,
        availableContentHeight / sourceHeight,
      ) *
      (settings.contentScale / 100);
  final contentWidth = math.max(1, (sourceWidth * fitScale).round());
  final contentHeight = math.max(1, (sourceHeight * fitScale).round());

  return LayoutInfo(
    targetWidth: targetWidth,
    targetHeight: targetHeight,
    contentX: (targetWidth - contentWidth) ~/ 2,
    contentY: math.max(0, (availableContentHeight - contentHeight) ~/ 2),
    contentWidth: contentWidth,
    contentHeight: contentHeight,
    infoPanelTop: targetHeight - infoPanelHeight,
    infoPanelHeight: infoPanelHeight,
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
    'bytes': encodeRasterImage(finalImage, outputFormat, jpegQuality),
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
    'composite_bytes': encodeRasterImage(
      composite,
      RasterOutputFormat.jpeg.name,
      88,
    ),
    'background_bytes': encodeRasterImage(
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
    final resized = downscaleForPreview(source, maxDimension);
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
  if (_usesPlainBackgroundForWatermarkBorder(settings)) {
    canvas.drawRect(dstRect, Paint()..color = Colors.white);
    return;
  }
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

  if (settings.classicInfoBorder.enabled && layoutInfo.infoPanelHeight > 0) {
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        layoutInfo.infoPanelTop.toDouble(),
        layoutInfo.targetWidth.toDouble(),
        layoutInfo.infoPanelHeight.toDouble(),
      ),
      Paint()..color = Colors.white,
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

Future<Uint8List> _applyClassicDecorations({
  required Uint8List rasterBytes,
  required ProcessingSettings settings,
  required ExifSnapshot exif,
  required LayoutInfo layoutInfo,
  required RasterOutputFormat outputFormat,
  required int jpegQuality,
}) async {
  final baseImage = await decodeUiImage(rasterBytes);
  final classicInfoBorderLogo = settings.classicInfoBorder.enabled
      ? await loadClassicInfoBorderLogo(
          resolveClassicInfoBorderLogoAsset(settings.classicInfoBorder, exif),
        )
      : null;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.drawImage(baseImage, Offset.zero, Paint());
  paintClassicInfoBorder(
    canvas: canvas,
    layoutInfo: layoutInfo,
    settings: settings.classicInfoBorder,
    exif: exif,
    logo: classicInfoBorderLogo,
  );
  if (settings.watermark.enabled) {
    paintWatermark(canvas, settings.watermark, exif, layoutInfo);
  }

  final picture = recorder.endRecording();
  final rendered = await picture.toImage(
    layoutInfo.targetWidth,
    layoutInfo.targetHeight,
  );
  final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
  classicInfoBorderLogo?.dispose();
  baseImage.dispose();
  rendered.dispose();
  picture.dispose();

  if (byteData == null) {
    throw StateError('Unable to render classic decorations.');
  }

  final pngBytes = byteData.buffer.asUint8List();
  if (outputFormat == RasterOutputFormat.jpeg) {
    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) {
      throw StateError('Unable to encode classic preview bytes.');
    }
    return img.encodeJpg(decoded, quality: jpegQuality);
  }

  return pngBytes;
}

bool _needsClassicDecorationPass(ProcessingSettings settings) {
  return settings.watermark.enabled || settings.classicInfoBorder.enabled;
}

bool _usesPlainBackgroundForWatermarkBorder(ProcessingSettings settings) {
  return settings.template == FrameTemplate.watermarkBorder;
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
  if (_usesPlainBackgroundForWatermarkBorder(settings)) {
    return img.Image(width: targetWidth, height: targetHeight, numChannels: 4)
      ..clear(img.ColorRgba8(255, 255, 255, 255));
  }
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

  if (settings.classicInfoBorder.enabled && targetHeight > 0) {
    final panelHeight = calculateClassicInfoBorderMetrics(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      settings: settings.classicInfoBorder,
    ).footerHeight.round();
    final panelTop = math.max(0, targetHeight - panelHeight);
    img.fillRect(
      bgFinal,
      x1: 0,
      y1: panelTop,
      x2: targetWidth - 1,
      y2: targetHeight - 1,
      color: img.ColorRgba8(255, 255, 255, 255),
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

ProcessingSettings _scaleSettingsForPreview(
  ProcessingSettings settings,
  double scale,
) {
  return settings.copyWith(
    blurRadius: scalePositiveInt(settings.blurRadius, scale),
    borderWidth: scalePositiveInt(settings.borderWidth, scale),
    cornerRadius: scalePositiveInt(settings.cornerRadius, scale),
    shadowSize: scalePositiveInt(settings.shadowSize, scale),
  );
}

WatermarkSettings _scaleWatermarkSettings(
  WatermarkSettings settings,
  double scale,
) {
  return settings.copyWith(
    fontSize: scalePositiveInt(settings.fontSize, scale),
    customX: (settings.customX * scale).round(),
    customY: (settings.customY * scale).round(),
  );
}

int _clampToByte(num value) => value.clamp(0, 255).round();

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
