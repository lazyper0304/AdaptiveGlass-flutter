import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:exif/exif.dart';
import 'package:image/image.dart' as img;

import '../models/frame_template.dart';
import '../models/processing_settings.dart';
import 'frame_processing_models.dart';
import 'frame_renderers/classic_frame_renderer.dart';
import 'frame_renderers/color_border_frame_renderer.dart';
import 'frame_renderers/color_walk_frame_renderer.dart';
import 'frame_renderers/renderer_utils.dart';

class AdaptiveGlassProcessor {
  AdaptiveGlassProcessor({
    ClassicFrameRenderer? classicRenderer,
    ColorBorderFrameRenderer? colorBorderRenderer,
    ColorWalkFrameRenderer? colorWalkRenderer,
  }) : _classicRenderer = classicRenderer ?? ClassicFrameRenderer(),
       _colorBorderRenderer = colorBorderRenderer ?? ColorBorderFrameRenderer(),
       _colorWalkRenderer = colorWalkRenderer ?? ColorWalkFrameRenderer();

  final ClassicFrameRenderer _classicRenderer;
  final ColorBorderFrameRenderer _colorBorderRenderer;
  final ColorWalkFrameRenderer _colorWalkRenderer;

  Future<ExifSnapshot> readExif(Uint8List sourceBytes) =>
      _readExif(sourceBytes);

  Future<List<PaletteSwatch>> extractPalette(
    Uint8List sourceBytes, {
    int count = 5,
  }) {
    return _colorBorderRenderer.extractPalette(sourceBytes, count: count);
  }

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
    switch (settings.template) {
      case FrameTemplate.classic:
      case FrameTemplate.watermarkBorder:
        return _classicRenderer.process(
          sourceBytes: sourceBytes,
          settings: settings,
          exif: exif,
          maxDimension: maxDimension,
          outputFormat: RasterOutputFormat.jpeg,
          jpegQuality: 88,
        );
      case FrameTemplate.colorBorder:
        return _colorBorderRenderer.process(
          sourceBytes: sourceBytes,
          settings: settings,
          exif: exif,
          maxDimension: maxDimension,
          outputFormat: RasterOutputFormat.jpeg,
          jpegQuality: 88,
        );
      case FrameTemplate.colorWalk:
        return _colorWalkRenderer.process(
          sourceBytes: sourceBytes,
          settings: settings,
          exif: exif,
          maxDimension: maxDimension,
          outputFormat: RasterOutputFormat.jpeg,
          jpegQuality: 88,
        );
    }
  }

  Future<PreviewCompositeOutput> processPreviewComposite(
    Uint8List sourceBytes,
    ProcessingSettings settings, {
    int maxDimension = 1600,
  }) {
    switch (settings.template) {
      case FrameTemplate.classic:
      case FrameTemplate.watermarkBorder:
        return _classicRenderer.processPreviewComposite(
          sourceBytes,
          settings,
          maxDimension: maxDimension,
        );
      case FrameTemplate.colorBorder:
        return _colorBorderRenderer.processPreviewComposite(
          sourceBytes,
          settings,
          maxDimension: maxDimension,
        );
      case FrameTemplate.colorWalk:
        return _colorWalkRenderer.processPreviewComposite(
          sourceBytes,
          settings,
          maxDimension: maxDimension,
        );
    }
  }

  Future<ProcessingOutput> processExport(
    Uint8List sourceBytes,
    ProcessingSettings settings, {
    ExifSnapshot? exif,
  }) async {
    final resolvedExif = exif ?? await _readExif(sourceBytes);
    switch (settings.template) {
      case FrameTemplate.classic:
      case FrameTemplate.watermarkBorder:
        return _classicRenderer.process(
          sourceBytes: sourceBytes,
          settings: settings,
          exif: resolvedExif,
          outputFormat: RasterOutputFormat.png,
        );
      case FrameTemplate.colorBorder:
        return _colorBorderRenderer.process(
          sourceBytes: sourceBytes,
          settings: settings,
          exif: resolvedExif,
          outputFormat: RasterOutputFormat.png,
        );
      case FrameTemplate.colorWalk:
        return _colorWalkRenderer.process(
          sourceBytes: sourceBytes,
          settings: settings,
          exif: resolvedExif,
          outputFormat: RasterOutputFormat.png,
        );
    }
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
        dateTimeOriginal: _extractPrintable(tags, const ['EXIF DateTimeOriginal']),
      );
    } catch (_) {
      return const ExifSnapshot();
    }
  }
}

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
