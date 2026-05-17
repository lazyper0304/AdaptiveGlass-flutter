import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../models/processing_settings.dart';
import '../frame_processing_models.dart';

const double _colorBorderLayoutLongEdge = 1440;
const double _colorBorderCircleSize = 64;
const double _colorBorderLabelWidth = 88;
const double _colorBorderLabelGap = 12;
const double _colorBorderLabelFontSize = 11;
const double _colorBorderMinCanvasWidth = 560;

class ColorBorderFrameRenderer {
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

    final metrics = calculateColorBorderLayoutMetrics(
      sourceWidth: image.width.toDouble(),
      sourceHeight: image.height.toDouble(),
      contentScale: settings.contentScale,
    );
    final logicalTargetWidth = math.max(1, metrics.canvasWidth.round());
    final logicalTargetHeight = math.max(1, metrics.canvasHeight.round());
    final exportScale = _calculateColorBorderExportScale(
      logicalTargetWidth,
      logicalTargetHeight,
    );
    final layoutInfo = LayoutInfo(
      targetWidth: _scaleDimension(logicalTargetWidth, exportScale),
      targetHeight: _scaleDimension(logicalTargetHeight, exportScale),
      contentX: _scalePosition(metrics.photoX, exportScale),
      contentY: _scalePosition(metrics.photoY, exportScale),
      contentWidth: _scaleDimension(metrics.photoWidth, exportScale),
      contentHeight: _scaleDimension(metrics.photoHeight, exportScale),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(exportScale);
    _paintColorBorderExport(
      canvas,
      image,
      metrics,
      palette,
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

class ColorBorderLayoutMetrics {
  const ColorBorderLayoutMetrics({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.photoX,
    required this.photoY,
    required this.photoWidth,
    required this.photoHeight,
    required this.circleRadius,
    required this.circleCenterY,
    required this.labelWidth,
    required this.circleCenters,
  });

  final double canvasWidth;
  final double canvasHeight;
  final double photoX;
  final double photoY;
  final double photoWidth;
  final double photoHeight;
  final double circleRadius;
  final double circleCenterY;
  final double labelWidth;
  final List<double> circleCenters;
}

class ColorBorderPaletteItemMetrics {
  const ColorBorderPaletteItemMetrics({
    required this.labelWidth,
    required this.circleSize,
    required this.circleTop,
    required this.circleBorderWidth,
    required this.circleGap,
    required this.labelTop,
    required this.labelFontSize,
  });

  final double labelWidth;
  final double circleSize;
  final double circleTop;
  final double circleBorderWidth;
  final double circleGap;
  final double labelTop;
  final double labelFontSize;
}

ColorBorderLayoutMetrics calculateColorBorderLayoutMetrics({
  required double sourceWidth,
  required double sourceHeight,
  required int contentScale,
}) {
  final layoutSource = _normalizeColorBorderSourceSize(
    sourceWidth,
    sourceHeight,
  );
  final scale = contentScale / 100;
  final contentWidth = layoutSource.width * scale;
  final contentHeight = layoutSource.height * scale;
  final unit = math.max(20.0, math.min(contentWidth, contentHeight) * 0.06);
  final outerBorder = math.max(14.0, unit * 0.45);
  final mattePadding = unit;
  final paletteHeight = math.max(120.0, contentHeight * 0.24);
  final framePadding = outerBorder + mattePadding;
  final canvasWidth = math.max(
    _colorBorderMinCanvasWidth,
    contentWidth + framePadding * 2,
  );
  final canvasHeight = contentHeight + framePadding * 2 + paletteHeight;
  final circleRadius = _colorBorderCircleSize / 2;
  final circleCenterY =
      framePadding +
      contentHeight +
      math.max(circleRadius + 8, paletteHeight / 3);
  final sidePadding = framePadding + math.max(circleRadius, 18);
  final minPaletteWidth =
      sidePadding * 2 +
      (_colorBorderLabelWidth * 5) +
      (_colorBorderLabelGap * 4);
  final resolvedCanvasWidth = math.max(canvasWidth, minPaletteWidth);
  final usableWidth = resolvedCanvasWidth - sidePadding * 2;
  final itemWidth = usableWidth / 5;
  final centers = List<double>.generate(
    5,
    (index) => sidePadding + (itemWidth * (index + 0.5)),
  );
  const labelWidth = _colorBorderLabelWidth;

  return ColorBorderLayoutMetrics(
    canvasWidth: resolvedCanvasWidth,
    canvasHeight: canvasHeight,
    photoX: (resolvedCanvasWidth - contentWidth) / 2,
    photoY: framePadding,
    photoWidth: contentWidth,
    photoHeight: contentHeight,
    circleRadius: circleRadius,
    circleCenterY: circleCenterY,
    labelWidth: labelWidth,
    circleCenters: centers,
  );
}

ColorBorderPaletteItemMetrics calculateColorBorderPaletteItemMetrics({
  required ColorBorderLayoutMetrics metrics,
  double scale = 1,
}) {
  final labelWidth = metrics.labelWidth * scale;
  final circleSize = _colorBorderCircleSize * scale;
  final circleTop = metrics.circleCenterY * scale - (circleSize / 2);
  final circleGap = 10 * scale;

  return ColorBorderPaletteItemMetrics(
    labelWidth: labelWidth,
    circleSize: circleSize,
    circleTop: circleTop,
    circleBorderWidth: math.max(2, 4 * scale),
    circleGap: circleGap,
    labelTop: circleTop + circleSize + circleGap,
    labelFontSize: math.max(7.0, _colorBorderLabelFontSize * scale),
  );
}

({double width, double height}) _normalizeColorBorderSourceSize(
  double width,
  double height,
) {
  final safeWidth = math.max(1.0, width);
  final safeHeight = math.max(1.0, height);
  final longestEdge = math.max(safeWidth, safeHeight);
  if (longestEdge <= _colorBorderLayoutLongEdge) {
    return (width: safeWidth, height: safeHeight);
  }

  final scale = _colorBorderLayoutLongEdge / longestEdge;
  return (width: safeWidth * scale, height: safeHeight * scale);
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

  final layers = _buildColorBorderLayers(
    sourceBytes: sourceBytes,
    settings: settings,
    maxDimension: maxDimension,
  );
  final finalImage = _composeColorBorderImage(
    canvas: layers.background.clone(),
    foreground: layers.foreground,
    layoutInfo: layers.layoutInfo,
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
  final layers = _buildColorBorderLayers(
    sourceBytes: sourceBytes,
    settings: settings,
    maxDimension: maxDimension,
  );
  final composite = _composeColorBorderImage(
    canvas: layers.background.clone(),
    foreground: layers.foreground,
    layoutInfo: layers.layoutInfo,
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
})
_buildColorBorderLayers({
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

  final normalizedSettings = renderScale >= 0.999
      ? settings
      : settings.copyWith(
          contentScale: _scalePositiveInt(settings.contentScale, renderScale),
        );
  final metrics = calculateColorBorderLayoutMetrics(
    sourceWidth: source.width.toDouble(),
    sourceHeight: source.height.toDouble(),
    contentScale: normalizedSettings.contentScale,
  );
  final contentWidth = math.max(1, metrics.photoWidth.round());
  final contentHeight = math.max(1, metrics.photoHeight.round());
  final foreground = img
      .copyResize(
        source,
        width: contentWidth,
        height: contentHeight,
        interpolation: img.Interpolation.cubic,
      )
      .convert(numChannels: 4);
  final background = img.Image(
    width: math.max(1, metrics.canvasWidth.round()),
    height: math.max(1, metrics.canvasHeight.round()),
    numChannels: 4,
  )..clear(img.ColorRgba8(255, 255, 255, 255));

  return (
    background: background,
    foreground: foreground,
    layoutInfo: LayoutInfo(
      targetWidth: background.width,
      targetHeight: background.height,
      contentX: math.max(0, metrics.photoX.round()),
      contentY: math.max(0, metrics.photoY.round()),
      contentWidth: contentWidth,
      contentHeight: contentHeight,
    ),
    renderScale: renderScale,
  );
}

img.Image _composeColorBorderImage({
  required img.Image canvas,
  required img.Image foreground,
  required LayoutInfo layoutInfo,
}) {
  final palette = _extractPaletteSwatches(
    foreground,
    count: 5,
  ).map((item) => item.toImageColor()).toList();
  final borderThickness = math.max(
    10,
    (math.min(layoutInfo.targetWidth, layoutInfo.targetHeight) * 0.022).round(),
  );

  _paintPhotoShadow(canvas, layoutInfo, borderThickness);
  img.compositeImage(
    canvas,
    foreground,
    dstX: layoutInfo.contentX,
    dstY: layoutInfo.contentY,
  );
  _paintPaletteRow(canvas, palette, layoutInfo, borderThickness);
  return canvas;
}

void _paintPhotoShadow(
  img.Image canvas,
  LayoutInfo layoutInfo,
  int borderThickness,
) {
  final pad = math.max(8, borderThickness);
  final shadow = img.Image(
    width: layoutInfo.contentWidth + pad * 2,
    height: layoutInfo.contentHeight + pad * 2,
    numChannels: 4,
  )..clear(img.ColorRgba8(0, 0, 0, 0));
  img.fillRect(
    shadow,
    x1: pad,
    y1: pad,
    x2: pad + layoutInfo.contentWidth - 1,
    y2: pad + layoutInfo.contentHeight - 1,
    color: img.ColorRgba8(0, 0, 0, 38),
  );
  img.gaussianBlur(shadow, radius: math.max(4, borderThickness ~/ 2));
  img.compositeImage(
    canvas,
    shadow,
    dstX: layoutInfo.contentX - pad,
    dstY: layoutInfo.contentY - (pad ~/ 3),
  );
}

void _paintPaletteRow(
  img.Image canvas,
  List<img.ColorRgba8> palette,
  LayoutInfo layoutInfo,
  int borderThickness,
) {
  final innerBottom = canvas.height - borderThickness;
  final availableHeight =
      innerBottom - (layoutInfo.contentY + layoutInfo.contentHeight);
  final circleRadius = math.max(12, math.min(28, canvas.width ~/ 30)).toInt();
  final circleCenterY =
      (layoutInfo.contentY +
              layoutInfo.contentHeight +
              math.max(circleRadius + 8, availableHeight ~/ 3))
          .toInt();
  final labelFont = circleRadius >= 24 ? img.arial24 : img.arial14;
  final labelColor = img.ColorRgba8(109, 98, 89, 255);
  final sidePadding = (borderThickness + math.max(circleRadius, 18)).toInt();
  final usableWidth = canvas.width - sidePadding * 2;
  final itemWidth = usableWidth / palette.length;
  final labelWidth = math.max(circleRadius * 3, (itemWidth * 0.92).round());
  final labelY = math
      .min(
        innerBottom - _fontHeight(labelFont) - 10,
        circleCenterY + circleRadius + math.max(10, circleRadius ~/ 2),
      )
      .toInt();

  for (var index = 0; index < palette.length; index++) {
    final centerX = palette.length == 1
        ? canvas.width ~/ 2
        : (sidePadding + (itemWidth * (index + 0.5))).round();
    final color = palette[index];
    img.fillCircle(
      canvas,
      x: centerX,
      y: circleCenterY,
      radius: math.max(circleRadius + 4, labelWidth ~/ 2),
      color: img.ColorRgba8(255, 255, 255, 255),
    );
    img.fillCircle(
      canvas,
      x: centerX,
      y: circleCenterY,
      radius: math.max(circleRadius + 2, (labelWidth ~/ 2) - 4),
      color: color,
    );
    final label = _hexCodeForColor(color);
    final estimatedWidth = _estimateTextWidth(label, labelFont);
    final labelX = (centerX - (estimatedWidth ~/ 2)).clamp(
      borderThickness,
      canvas.width - borderThickness - estimatedWidth,
    );
    img.drawString(
      canvas,
      label,
      x: labelX,
      y: labelY,
      font: labelFont,
      color: labelColor,
    );
  }
}

String _hexCodeForColor(img.ColorRgba8 color) =>
    '#${_hexPart(color.r)}${_hexPart(color.g)}${_hexPart(color.b)}';

String _hexPart(num value) =>
    value.round().toRadixString(16).padLeft(2, '0').toUpperCase();

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

int _colorDistance(PaletteSwatch left, PaletteSwatch right) {
  return ((left.red - right.red).abs() +
          (left.green - right.green).abs() +
          (left.blue - right.blue).abs())
      .round();
}

int _estimateTextWidth(String text, img.BitmapFont font) {
  final glyphWidth = identical(font, img.arial24) ? 13 : 8;
  return text.length * glyphWidth;
}

int _fontHeight(img.BitmapFont font) {
  return identical(font, img.arial24) ? 24 : 14;
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

double _calculateColorBorderExportScale(int width, int height) {
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

void _paintColorBorderExport(
  Canvas canvas,
  ui.Image image,
  ColorBorderLayoutMetrics metrics,
  List<PaletteSwatch> palette, {
  required Size canvasSize,
}) {
  final canvasRect = Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);
  canvas.drawRect(canvasRect, Paint()..color = Colors.white);

  final photoRect = Rect.fromLTWH(
    metrics.photoX,
    metrics.photoY,
    metrics.photoWidth,
    metrics.photoHeight,
  );

  final shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.15)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 22);
  canvas.drawRect(photoRect.shift(const Offset(0, 8)), shadowPaint);
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    photoRect,
    Paint()..filterQuality = FilterQuality.high,
  );

  final swatches = palette.isEmpty
      ? List<PaletteSwatch>.filled(
          5,
          const PaletteSwatch(red: 236, green: 226, blue: 214),
        )
      : palette;
  final itemMetrics = calculateColorBorderPaletteItemMetrics(metrics: metrics);
  final circleRadius = itemMetrics.circleSize / 2;

  for (
    var index = 0;
    index < swatches.length && index < metrics.circleCenters.length;
    index++
  ) {
    final center = Offset(
      metrics.circleCenters[index],
      itemMetrics.circleTop + circleRadius,
    );
    canvas.drawCircle(
      center,
      circleRadius,
      Paint()
        ..color = swatches[index].toColor()
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      circleRadius - (itemMetrics.circleBorderWidth / 2),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = itemMetrics.circleBorderWidth,
    );

    final labelPainter =
        TextPainter(
          textAlign: TextAlign.center,
          textWidthBasis: TextWidthBasis.parent,
          text: TextSpan(
            text: swatches[index].hexCode,
            style: TextStyle(
              color: const Color(0xFF6D6259),
              fontSize: itemMetrics.labelFontSize,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '',
        )..layout(
          minWidth: itemMetrics.labelWidth,
          maxWidth: itemMetrics.labelWidth,
        );
    labelPainter.paint(
      canvas,
      Offset(center.dx - (itemMetrics.labelWidth / 2), itemMetrics.labelTop),
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
