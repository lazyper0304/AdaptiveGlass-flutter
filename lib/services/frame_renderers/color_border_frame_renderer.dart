import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../models/processing_settings.dart';
import '../frame_processing_models.dart';

class ColorBorderFrameRenderer {
  Future<List<PaletteSwatch>> extractPalette(
    Uint8List sourceBytes, {
    int count = 5,
  }) async {
    final result = await compute(_extractPaletteTask, <String, Object?>{
      'bytes': sourceBytes,
      'count': count,
    });
    return result
        .map((item) => PaletteSwatch.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ProcessingOutput> process({
    required Uint8List sourceBytes,
    required ProcessingSettings settings,
    required ExifSnapshot exif,
    required RasterOutputFormat outputFormat,
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

ColorBorderLayoutMetrics calculateColorBorderLayoutMetrics({
  required double sourceWidth,
  required double sourceHeight,
  required int contentScale,
}) {
  final scale = contentScale / 100;
  final contentWidth = sourceWidth * scale;
  final contentHeight = sourceHeight * scale;
  final unit = math.max(20.0, math.min(contentWidth, contentHeight) * 0.06);
  final outerBorder = math.max(14.0, unit * 0.45);
  final mattePadding = unit;
  final paletteHeight = math.max(120.0, contentHeight * 0.24);
  final canvasWidth = contentWidth + (outerBorder + mattePadding) * 2;
  final canvasHeight =
      contentHeight + (outerBorder + mattePadding) * 2 + paletteHeight;
  final circleRadius = math.max(12.0, math.min(28.0, canvasWidth / 30));
  final circleCenterY =
      outerBorder +
      mattePadding +
      contentHeight +
      math.max(circleRadius + 8, paletteHeight / 3);
  final sidePadding = outerBorder + math.max(circleRadius, 18);
  final usableWidth = canvasWidth - sidePadding * 2;
  final itemWidth = usableWidth / 5;
  final centers = List<double>.generate(
    5,
    (index) => sidePadding + (itemWidth * (index + 0.5)),
  );
  final labelWidth = math.max(circleRadius * 2.6, itemWidth * 0.92);

  return ColorBorderLayoutMetrics(
    canvasWidth: canvasWidth,
    canvasHeight: canvasHeight,
    photoX: outerBorder + mattePadding,
    photoY: outerBorder + mattePadding,
    photoWidth: contentWidth,
    photoHeight: contentHeight,
    circleRadius: circleRadius,
    circleCenterY: circleCenterY,
    labelWidth: labelWidth,
    circleCenters: centers,
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
  final palette = _extractPaletteSwatches(foreground, count: 5)
      .map((item) => item.toImageColor())
      .toList();
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
  final labelY = math.min(
    innerBottom - _fontHeight(labelFont) - 10,
    circleCenterY + circleRadius + math.max(10, circleRadius ~/ 2),
  ).toInt();

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
  return _extractPaletteSwatches(source, count: count)
      .map((item) => item.toJson())
      .toList();
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
