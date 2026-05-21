import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../models/color_walk_settings.dart';
import '../../models/processing_settings.dart';
import '../frame_processing_models.dart';

const double _colorWalkMinCanvasWidth = 560;
const double _colorWalkMinCanvasHeight = 560;

class ColorWalkFrameRenderer {
  Future<List<PaletteSwatch>> extractPalette(
    Uint8List sourceBytes, {
    int count = 5,
  }) async {
    try {
      return await _extractPaletteWithUiCodec(sourceBytes, count: count);
    } catch (_) {
      final result = await compute(_extractPaletteTask, <String, Object?>{
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
    final paletteFuture = compute(_extractPaletteTask, <String, Object?>{
      'bytes': sourceBytes,
      'count': 5,
    });
    final image = await _decodeUiImage(sourceBytes);
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
    final exportScale = _calculateColorWalkExportScale(
      logicalTargetWidth,
      logicalTargetHeight,
    );
    final layoutInfo = LayoutInfo(
      targetWidth: _scaleDimension(logicalTargetWidth, exportScale),
      targetHeight: _scaleDimension(logicalTargetHeight, exportScale),
      contentX: _scalePosition(metrics.contentX, exportScale),
      contentY: _scalePosition(metrics.contentY, exportScale),
      contentWidth: _scaleDimension(metrics.contentWidth, exportScale),
      contentHeight: _scaleDimension(metrics.contentHeight, exportScale),
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
    final bytes = await _encodeUiImage(rendered, outputFormat, jpegQuality);

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
      paletteAreaHeight = math.max(180.0, canvasWidth * 0.4);
      canvasHeight = contentHeight + paletteAreaHeight;
      contentX = (canvasWidth - contentWidth) / 2;
      contentY = paletteAreaHeight;
      paletteAreaOffset = Offset(0, 0);
      break;
    case ColorWalkPosition.bottom:
      canvasWidth = math.max(_colorWalkMinCanvasWidth, contentWidth);
      paletteAreaWidth = canvasWidth;
      paletteAreaHeight = math.max(180.0, canvasWidth * 0.4);
      canvasHeight = contentHeight + paletteAreaHeight;
      contentX = (canvasWidth - contentWidth) / 2;
      contentY = 0;
      paletteAreaOffset = Offset(0, contentHeight);
      break;
    case ColorWalkPosition.left:
      canvasHeight = math.max(_colorWalkMinCanvasHeight, contentHeight);
      paletteAreaHeight = canvasHeight;
      paletteAreaWidth = math.max(180.0, canvasHeight * 0.4);
      canvasWidth = contentWidth + paletteAreaWidth;
      contentX = paletteAreaWidth;
      contentY = (canvasHeight - contentHeight) / 2;
      paletteAreaOffset = Offset(0, 0);
      break;
    case ColorWalkPosition.right:
      canvasHeight = math.max(_colorWalkMinCanvasHeight, contentHeight);
      paletteAreaHeight = canvasHeight;
      paletteAreaWidth = math.max(180.0, canvasHeight * 0.4);
      canvasWidth = contentWidth + paletteAreaWidth;
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
    'bytes': _encodeRaster(finalImage, outputFormat, jpegQuality),
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
    final resized = _downscaleForPreview(source, maxDimension);
    source = resized.image;
    renderScale = resized.scale;
  }

  final colorWalkSettings = settings.colorWalk;
  final normalizedSettings = renderScale >= 0.999
      ? colorWalkSettings
      : colorWalkSettings.copyWith(
          contentScale: _scalePositiveInt(colorWalkSettings.contentScale, renderScale),
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

  final palette = _extractPaletteSwatches(source, count: 5);
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

  final paletteAreaSize = (canvas.width * 0.4).round();
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

List<PaletteSwatch> _extractPaletteSwatches(
  img.Image image, {
  required int count,
}) {
  final sampled = img.copyResize(
    image,
    width: 72,
    height: math.max(1, (image.height * (72 / image.width)).round()),
    interpolation: img.Interpolation.linear,
  );
  final buckets = <int, _PaletteBucket>{};

  for (final pixel in sampled) {
    if (pixel.a < 200) {
      continue;
    }
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();
    final saturation =
        math.max(r, math.max(g, b)) - math.min(r, math.min(g, b));
    final brightness = (r + g + b) / 3;
    final weight = (saturation + (brightness < 240 ? 28 : 8)).round();
    final key = ((r ~/ 32) << 10) | ((g ~/ 32) << 5) | (b ~/ 32);
    buckets.putIfAbsent(key, _PaletteBucket.new).add(r, g, b, weight);
  }

  return _buildPaletteFromBuckets(buckets, count: count);
}

List<PaletteSwatch> _buildPaletteFromBuckets(
  Map<int, _PaletteBucket> buckets, {
  required int count,
}) {
  final sorted = buckets.values.toList()
    ..sort((a, b) => b.weight.compareTo(a.weight));

  final palette = <PaletteSwatch>[];
  for (final bucket in sorted) {
    final candidate = bucket.toColor();
    if (palette.every((color) => _colorDistance(color, candidate) >= 84)) {
      palette.add(candidate);
    }
    if (palette.length == count) {
      break;
    }
  }

  if (palette.length < count) {
    for (final bucket in sorted) {
      final candidate = bucket.toColor();
      final exists = palette.any(
        (color) =>
            color.red == candidate.red &&
            color.green == candidate.green &&
            color.blue == candidate.blue,
      );
      if (!exists) {
        palette.add(candidate);
      }
      if (palette.length == count) {
        break;
      }
    }
  }

  while (palette.length < count) {
    palette.add(
      palette.isNotEmpty
          ? palette.last
          : const PaletteSwatch(red: 236, green: 226, blue: 214),
    );
  }

  return palette;
}

int _colorDistance(PaletteSwatch left, PaletteSwatch right) {
  return ((left.red - right.red).abs() +
          (left.green - right.green).abs() +
          (left.blue - right.blue).abs())
      .round();
}

List<Map<String, int>> _extractPaletteTask(Map<String, Object?> input) {
  final sourceBytes = input['bytes']! as Uint8List;
  final count = (input['count'] as num?)?.round() ?? 5;
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) {
    return List.generate(
      count,
      (_) => const PaletteSwatch(red: 236, green: 226, blue: 214).toJson(),
    );
  }

  final source = img.bakeOrientation(decoded).convert(numChannels: 4);
  return _extractPaletteSwatches(
    source,
    count: count,
  ).map((item) => item.toJson()).toList();
}

Future<List<PaletteSwatch>> _extractPaletteWithUiCodec(
  Uint8List sourceBytes, {
  required int count,
}) async {
  const sampleLongEdge = 96.0;
  final buffer = await ui.ImmutableBuffer.fromUint8List(sourceBytes);
  ui.ImageDescriptor? descriptor;

  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final sourceWidth = math.max(1, descriptor.width);
    final sourceHeight = math.max(1, descriptor.height);
    final scale = math.min(
      1.0,
      sampleLongEdge / math.max(sourceWidth, sourceHeight),
    );
    final targetWidth = math.max(1, (sourceWidth * scale).round());
    final targetHeight = math.max(1, (sourceHeight * scale).round());
    final codec = await descriptor.instantiateCodec(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );

    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        final byteData = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        if (byteData == null) {
          throw StateError('无法读取预览取色像素。');
        }
        return _extractPaletteSwatchesFromRgba(
          byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          ),
          width: image.width,
          height: image.height,
          count: count,
        );
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  } finally {
    descriptor?.dispose();
    buffer.dispose();
  }
}

List<PaletteSwatch> _extractPaletteSwatchesFromRgba(
  Uint8List rgbaBytes, {
  required int width,
  required int height,
  required int count,
}) {
  final buckets = <int, _PaletteBucket>{};
  final pixelCount = math.min(width * height, rgbaBytes.length ~/ 4);

  for (var pixelIndex = 0; pixelIndex < pixelCount; pixelIndex++) {
    final offset = pixelIndex * 4;
    final r = rgbaBytes[offset];
    final g = rgbaBytes[offset + 1];
    final b = rgbaBytes[offset + 2];
    final a = rgbaBytes[offset + 3];
    if (a < 200) {
      continue;
    }

    final saturation =
        math.max(r, math.max(g, b)) - math.min(r, math.min(g, b));
    final brightness = (r + g + b) / 3;
    final weight = (saturation + (brightness < 240 ? 28 : 8)).round();
    final key = ((r ~/ 32) << 10) | ((g ~/ 32) << 5) | (b ~/ 32);
    buckets.putIfAbsent(key, _PaletteBucket.new).add(r, g, b, weight);
  }

  return _buildPaletteFromBuckets(buckets, count: count);
}

class _PaletteBucket {
  int red = 0;
  int green = 0;
  int blue = 0;
  int weight = 0;

  void add(int r, int g, int b, int nextWeight) {
    red += r * nextWeight;
    green += g * nextWeight;
    blue += b * nextWeight;
    weight += nextWeight;
  }

  PaletteSwatch toColor() {
    if (weight == 0) {
      return const PaletteSwatch(red: 236, green: 226, blue: 214);
    }
    return PaletteSwatch(
      red: (red / weight).round(),
      green: (green / weight).round(),
      blue: (blue / weight).round(),
    );
  }
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

int _scalePositiveInt(int value, double scale) {
  if (value <= 0) {
    return value;
  }
  return math.max(1, (value * scale).round());
}

double _calculateColorWalkExportScale(int width, int height) {
  const targetLongEdge = 4096.0;
  const maxScale = 2.0;
  final longestEdge = math.max(width, height).toDouble();
  if (longestEdge >= targetLongEdge) {
    return 1.0;
  }
  return math.min(maxScale, targetLongEdge / longestEdge);
}

int _scaleDimension(num value, double scale) =>
    math.max(1, (value * scale).round());

int _scalePosition(num value, double scale) =>
    math.max(0, (value * scale).round());

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