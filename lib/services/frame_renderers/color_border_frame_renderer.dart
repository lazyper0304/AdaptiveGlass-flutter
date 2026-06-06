import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../models/processing_settings.dart';
import '../frame_processing_models.dart';
import 'palette_extractor.dart';
import 'renderer_utils.dart';

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

    final metrics = calculateColorBorderLayoutMetrics(
      sourceWidth: image.width.toDouble(),
      sourceHeight: image.height.toDouble(),
      contentScale: settings.contentScale,
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
      contentX: scalePosition(metrics.photoX, exportScale),
      contentY: scalePosition(metrics.photoY, exportScale),
      contentWidth: scaleDimension(metrics.photoWidth, exportScale),
      contentHeight: scaleDimension(metrics.photoHeight, exportScale),
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
    final resized = downscaleForPreview(source, maxDimension);
    source = resized.image;
    renderScale = resized.scale;
  }

  final normalizedSettings = renderScale >= 0.999
      ? settings
      : settings.copyWith(
          contentScale: scalePositiveInt(settings.contentScale, renderScale),
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
  final palette = extractPaletteSwatches(
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

int _estimateTextWidth(String text, img.BitmapFont font) {
  final glyphWidth = identical(font, img.arial24) ? 13 : 8;
  return text.length * glyphWidth;
}

int _fontHeight(img.BitmapFont font) {
  return identical(font, img.arial24) ? 24 : 14;
}

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
