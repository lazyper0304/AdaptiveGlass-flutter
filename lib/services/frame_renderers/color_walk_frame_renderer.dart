import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../models/color_walk_settings.dart';
import '../../models/processing_settings.dart';
import '../frame_processing_models.dart';
import 'palette_extractor.dart';
import 'renderer_utils.dart';

const double _colorWalkMinCanvasWidth = 560;
const double _colorWalkMinCanvasHeight = 560;

class ColorWalkFrameRenderer {
  Future<List<PaletteSwatch>> extractPalette(
    Uint8List sourceBytes, {
    int count = 5,
  }) async {
    try {
      return await extractPaletteWithUiCodec(sourceBytes, count: count);
    } catch (_) {
      final result = await compute(extractPaletteTask, <String, Object?>{
        'bytes': sourceBytes,
        'count': count,
      });
      return result
          .map(
            (item) => PaletteSwatch.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }
  }

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

    return ProcessingOutput(
      imageBytes: rasterResult['bytes']! as Uint8List,
      layoutInfo: LayoutInfo.fromJson(
        Map<String, dynamic>.from(rasterResult['layout']! as Map),
      ),
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
    final paletteFuture = compute(extractPaletteTask, <String, Object?>{
      'bytes': sourceBytes,
      'count': 5,
    });
    final image = await decodeUiImage(sourceBytes);
    final paletteJson = await paletteFuture;
    final palette = paletteJson
        .map((item) => PaletteSwatch.fromJson(Map<String, dynamic>.from(item)))
        .toList();

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
    final logicalTargetWidth = math.max(1, metrics.canvasWidth.round());
    final logicalTargetHeight = math.max(1, metrics.canvasHeight.round());
    final exportScale = calculateExportScale(
      logicalTargetWidth,
      logicalTargetHeight,
    );
    final layoutInfo = LayoutInfo(
      targetWidth: scaleDimension(logicalTargetWidth, exportScale),
      targetHeight: scaleDimension(logicalTargetHeight, exportScale),
      contentX: scalePosition(metrics.contentX, exportScale),
      contentY: scalePosition(metrics.contentY, exportScale),
      contentWidth: scaleDimension(metrics.contentWidth, exportScale),
      contentHeight: scaleDimension(metrics.contentHeight, exportScale),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(exportScale);
    _paintColorWalkExport(
      canvas,
      image,
      metrics,
      selectedColor,
      palette,
      colorWalkSettings,
      exif,
      canvasSize: Size(
        logicalTargetWidth.toDouble(),
        logicalTargetHeight.toDouble(),
      ),
    );

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(
      layoutInfo.targetWidth,
      layoutInfo.targetHeight,
    );
    final bytes = await encodeUiImage(rendered, outputFormat, jpegQuality);

    image.dispose();
    rendered.dispose();
    picture.dispose();

    return ProcessingOutput(
      imageBytes: bytes,
      layoutInfo: layoutInfo,
      exif: exif,
    );
  }
}

class ColorWalkLayoutMetrics {
  const ColorWalkLayoutMetrics({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.contentX,
    required this.contentY,
    required this.contentWidth,
    required this.contentHeight,
    required this.position,
    required this.paletteAreaWidth,
    required this.paletteAreaHeight,
    required this.paletteAreaOffset,
  });

  final double canvasWidth;
  final double canvasHeight;
  final double contentX;
  final double contentY;
  final double contentWidth;
  final double contentHeight;
  final ColorWalkPosition position;
  final double paletteAreaWidth;
  final double paletteAreaHeight;
  final Offset paletteAreaOffset;
}

ColorWalkLayoutMetrics calculateColorWalkLayoutMetrics({
  required double sourceWidth,
  required double sourceHeight,
  required int contentScale,
  required ColorWalkPosition position,
}) {
  final scale = contentScale / 100;
  final contentWidth = sourceWidth * scale;
  final contentHeight = sourceHeight * scale;

  double canvasWidth, canvasHeight, contentX, contentY;
  double paletteAreaWidth, paletteAreaHeight;
  Offset paletteAreaOffset;

  switch (position) {
    case ColorWalkPosition.top:
      canvasWidth = math.max(_colorWalkMinCanvasWidth, contentWidth);
      paletteAreaWidth = canvasWidth;
      canvasHeight = math.max(_colorWalkMinCanvasHeight, contentHeight / 0.55);
      paletteAreaHeight = canvasHeight * 0.45;
      contentX = (canvasWidth - contentWidth) / 2;
      contentY = paletteAreaHeight;
      paletteAreaOffset = Offset(0, 0);
      break;
    case ColorWalkPosition.bottom:
      canvasWidth = math.max(_colorWalkMinCanvasWidth, contentWidth);
      paletteAreaWidth = canvasWidth;
      canvasHeight = math.max(_colorWalkMinCanvasHeight, contentHeight / 0.55);
      paletteAreaHeight = canvasHeight * 0.45;
      contentX = (canvasWidth - contentWidth) / 2;
      contentY = 0;
      paletteAreaOffset = Offset(0, contentHeight);
      break;
    case ColorWalkPosition.left:
      canvasHeight = math.max(_colorWalkMinCanvasHeight, contentHeight);
      paletteAreaHeight = canvasHeight;
      canvasWidth = math.max(_colorWalkMinCanvasWidth, contentWidth / 0.55);
      paletteAreaWidth = canvasWidth * 0.45;
      contentX = paletteAreaWidth;
      contentY = (canvasHeight - contentHeight) / 2;
      paletteAreaOffset = Offset(0, 0);
      break;
    case ColorWalkPosition.right:
      canvasHeight = math.max(_colorWalkMinCanvasHeight, contentHeight);
      paletteAreaHeight = canvasHeight;
      canvasWidth = math.max(_colorWalkMinCanvasWidth, contentWidth / 0.55);
      paletteAreaWidth = canvasWidth * 0.45;
      contentX = 0;
      contentY = (canvasHeight - contentHeight) / 2;
      paletteAreaOffset = Offset(contentWidth, 0);
      break;
  }

  return ColorWalkLayoutMetrics(
    canvasWidth: canvasWidth,
    canvasHeight: canvasHeight,
    contentX: contentX,
    contentY: contentY,
    contentWidth: contentWidth,
    contentHeight: contentHeight,
    position: position,
    paletteAreaWidth: paletteAreaWidth,
    paletteAreaHeight: paletteAreaHeight,
    paletteAreaOffset: paletteAreaOffset,
  );
}

Future<Map<String, Object?>> _processRasterTask(
  Map<String, Object?> input,
) async {
  final sourceBytes = input['bytes']! as Uint8List;
  final settings = ProcessingSettings.fromJson(
    Map<String, dynamic>.from(input['settings']! as Map),
  );
  final maxDimension = (input['max_dimension'] as num?)?.round();
  final outputFormat =
      input['output_format'] as String? ?? RasterOutputFormat.png.name;
  final jpegQuality = (input['jpeg_quality'] as num?)?.round() ?? 95;

  final layers = _buildColorWalkLayers(
    sourceBytes: sourceBytes,
    settings: settings,
    maxDimension: maxDimension,
  );
  final finalImage = _composeColorWalkImage(
    canvas: layers.background.clone(),
    foreground: layers.foreground,
    layoutInfo: layers.layoutInfo,
    palette: layers.palette,
    colorWalkSettings: settings.colorWalk,
    exif: const ExifSnapshot(),
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
  final settings = ProcessingSettings.fromJson(
    Map<String, dynamic>.from(input['settings']! as Map),
  );
  final maxDimension = (input['max_dimension'] as num?)?.round();
  final layers = _buildColorWalkLayers(
    sourceBytes: sourceBytes,
    settings: settings,
    maxDimension: maxDimension,
  );
  final composite = _composeColorWalkImage(
    canvas: layers.background.clone(),
    foreground: layers.foreground,
    layoutInfo: layers.layoutInfo,
    palette: layers.palette,
    colorWalkSettings: settings.colorWalk,
    exif: const ExifSnapshot(),
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
  List<PaletteSwatch> palette,
})
_buildColorWalkLayers({
  required Uint8List sourceBytes,
  required ProcessingSettings settings,
  required int? maxDimension,
}) {
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

  final colorWalkSettings = settings.colorWalk;
  final normalizedSettings = renderScale >= 0.999
      ? colorWalkSettings
      : colorWalkSettings.copyWith(
          contentScale: scalePositiveInt(colorWalkSettings.contentScale, renderScale),
        );

  final metrics = calculateColorWalkLayoutMetrics(
    sourceWidth: source.width.toDouble(),
    sourceHeight: source.height.toDouble(),
    contentScale: normalizedSettings.contentScale,
    position: normalizedSettings.position,
  );

  final contentWidth = math.max(1, metrics.contentWidth.round());
  final contentHeight = math.max(1, metrics.contentHeight.round());
  final foreground = img
      .copyResize(
        source,
        width: contentWidth,
        height: contentHeight,
        interpolation: img.Interpolation.cubic,
      )
      .convert(numChannels: 4);

  final palette = extractPaletteSwatches(source, count: 5);
  final selectedColor = palette.isNotEmpty &&
          normalizedSettings.selectedColorIndex >= 0 &&
          normalizedSettings.selectedColorIndex < palette.length
      ? palette[normalizedSettings.selectedColorIndex]
      : const PaletteSwatch(red: 236, green: 226, blue: 214);

  final background = img.Image(
    width: math.max(1, metrics.canvasWidth.round()),
    height: math.max(1, metrics.canvasHeight.round()),
    numChannels: 4,
  );
  img.fillRect(
    background,
    x1: 0,
    y1: 0,
    x2: math.max(1, metrics.canvasWidth.round()) - 1,
    y2: math.max(1, metrics.canvasHeight.round()) - 1,
    color: img.ColorRgba8(selectedColor.red, selectedColor.green, selectedColor.blue, 255),
  );

  return (
    background: background,
    foreground: foreground,
    layoutInfo: LayoutInfo(
      targetWidth: background.width,
      targetHeight: background.height,
      contentX: math.max(0, metrics.contentX.round()),
      contentY: math.max(0, metrics.contentY.round()),
      contentWidth: contentWidth,
      contentHeight: contentHeight,
    ),
    renderScale: renderScale,
    palette: palette,
  );
}

img.Image _composeColorWalkImage({
  required img.Image canvas,
  required img.Image foreground,
  required LayoutInfo layoutInfo,
  required List<PaletteSwatch> palette,
  required ColorWalkSettings colorWalkSettings,
  required ExifSnapshot exif,
}) {
  img.compositeImage(
    canvas,
    foreground,
    dstX: layoutInfo.contentX,
    dstY: layoutInfo.contentY,
  );

  final paletteAreaSize = (canvas.width * 0.45).round();
  _paintColorWalkPaletteArea(
    canvas,
    palette,
    colorWalkSettings,
    exif,
    paletteAreaSize,
  );

  return canvas;
}

void _paintColorWalkPaletteArea(
  img.Image canvas,
  List<PaletteSwatch> palette,
  ColorWalkSettings settings,
  ExifSnapshot exif,
  int paletteAreaSize,
) {
  final isVertical = settings.position == ColorWalkPosition.left ||
      settings.position == ColorWalkPosition.right;

  int areaX, areaY, areaWidth, areaHeight;

  switch (settings.position) {
    case ColorWalkPosition.top:
      areaX = 0;
      areaY = 0;
      areaWidth = canvas.width;
      areaHeight = paletteAreaSize;
      break;
    case ColorWalkPosition.bottom:
      areaX = 0;
      areaY = canvas.height - paletteAreaSize;
      areaWidth = canvas.width;
      areaHeight = paletteAreaSize;
      break;
    case ColorWalkPosition.left:
      areaX = 0;
      areaY = 0;
      areaWidth = paletteAreaSize;
      areaHeight = canvas.height;
      break;
    case ColorWalkPosition.right:
      areaX = canvas.width - paletteAreaSize;
      areaY = 0;
      areaWidth = paletteAreaSize;
      areaHeight = canvas.height;
      break;
  }

  final circleRadius = math.max(12, math.min(24, paletteAreaSize ~/ 8));
  final circleSize = circleRadius * 2;

  final paletteCount = palette.length;
  final spacing = (isVertical ? areaHeight : areaWidth - circleSize * paletteCount) ~/ (paletteCount + 1);

  for (var i = 0; i < paletteCount; i++) {
    int circleX, circleY;
    if (isVertical) {
      circleX = areaX + (areaWidth - circleSize) ~/ 2;
      circleY = areaY + spacing + i * (circleSize + spacing);
    } else {
      circleX = areaX + spacing + i * (circleSize + spacing);
      circleY = areaY + (areaHeight - circleSize) ~/ 2;
    }

    img.fillCircle(
      canvas,
      x: circleX + circleRadius,
      y: circleY + circleRadius,
      radius: circleRadius + 4,
      color: img.ColorRgba8(255, 255, 255, 255),
    );

    final color = palette[i];
    img.fillCircle(
      canvas,
      x: circleX + circleRadius,
      y: circleY + circleRadius,
      radius: circleRadius,
      color: img.ColorRgba8(color.red, color.green, color.blue, 255),
    );

    if (i == settings.selectedColorIndex) {
      img.drawCircle(
        canvas,
        x: circleX + circleRadius,
        y: circleY + circleRadius,
        radius: circleRadius + 8,
        color: img.ColorRgba8(255, 255, 255, 255),
      );
    }
  }

  final textX = areaX + (areaWidth ~/ 2);
  final textY = areaY + (areaHeight ~/ 2) - settings.customTextSize ~/ 2;
  final labelFont = settings.customTextSize >= 20 ? img.arial24 : img.arial14;
  final labelColor = img.ColorRgba8(255, 255, 255, 200);

  if (settings.customText.isNotEmpty) {
    img.drawString(
      canvas,
      settings.customText,
      x: textX,
      y: textY,
      font: labelFont,
      color: labelColor,
    );
  }

  if (settings.showDateTime && exif.dateTimeOriginal.isNotEmpty) {
    final dateText = exif.dateTimeOriginal.split(' ').first;
    final timeY = textY + settings.customTextSize + 4;
    img.drawString(
      canvas,
      dateText,
      x: textX,
      y: timeY,
      font: img.arial14,
      color: labelColor,
    );
  }
}

void _paintColorWalkExport(
  Canvas canvas,
  ui.Image image,
  ColorWalkLayoutMetrics metrics,
  PaletteSwatch selectedColor,
  List<PaletteSwatch> palette,
  ColorWalkSettings colorWalkSettings,
  ExifSnapshot exif, {
  required Size canvasSize,
}) {
  final canvasRect = Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);
  canvas.drawRect(
    canvasRect,
    Paint()..color = selectedColor.toColor(),
  );

  final contentRect = Rect.fromLTWH(
    metrics.contentX,
    metrics.contentY,
    metrics.contentWidth,
    metrics.contentHeight,
  );

  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    contentRect,
    Paint()..filterQuality = FilterQuality.high,
  );

  _paintPaletteArea(
    canvas,
    metrics,
    palette,
    colorWalkSettings,
    exif,
  );
}

void _paintPaletteArea(
  Canvas canvas,
  ColorWalkLayoutMetrics metrics,
  List<PaletteSwatch> palette,
  ColorWalkSettings settings,
  ExifSnapshot exif,
) {
  final isVertical = settings.position == ColorWalkPosition.left ||
      settings.position == ColorWalkPosition.right;

  final paletteAreaWidth = metrics.paletteAreaWidth;
  final paletteAreaHeight = metrics.paletteAreaHeight;
  final paletteAreaOffset = metrics.paletteAreaOffset;

  final circleRadius = math.max(12.0, math.min(24.0, (isVertical ? paletteAreaWidth : paletteAreaHeight) / 8));
  final circleSize = circleRadius * 2;

  final paletteCount = palette.length;
  final spacing = (isVertical ? paletteAreaHeight : paletteAreaWidth - circleSize * paletteCount) / (paletteCount + 1);

  for (var i = 0; i < paletteCount; i++) {
    double circleX, circleY;
    if (isVertical) {
      circleX = paletteAreaOffset.dx + (paletteAreaWidth - circleSize) / 2;
      circleY = paletteAreaOffset.dy + spacing + i * (circleSize + spacing);
    } else {
      circleX = paletteAreaOffset.dx + spacing + i * (circleSize + spacing);
      circleY = paletteAreaOffset.dy + (paletteAreaHeight - circleSize) / 2;
    }

    final center = Offset(circleX + circleRadius, circleY + circleRadius);

    canvas.drawCircle(
      center,
      circleRadius + 4,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      center,
      circleRadius,
      Paint()..color = palette[i].toColor(),
    );

    if (i == settings.selectedColorIndex) {
      canvas.drawCircle(
        center,
        circleRadius + 8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  final textX = paletteAreaOffset.dx + paletteAreaWidth / 2;
  final textY = paletteAreaOffset.dy + paletteAreaHeight / 2 - settings.customTextSize / 2;

  if (settings.customText.isNotEmpty) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: settings.customText,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: settings.customTextSize.toDouble(),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(textX - textPainter.width / 2, textY),
    );
  }

  if (settings.showDateTime && exif.dateTimeOriginal.isNotEmpty) {
    final dateText = exif.dateTimeOriginal.split(' ').first;
    final dateY = textY + settings.customTextSize + 4;

    final datePainter = TextPainter(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: dateText,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: settings.dateTimeTextSize.toDouble(),
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    datePainter.paint(
      canvas,
      Offset(textX - datePainter.width / 2, dateY),
    );
  }
}
