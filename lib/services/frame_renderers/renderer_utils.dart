import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

import '../frame_processing_models.dart';

Uint8List encodeRasterImage(img.Image image, String format, int jpegQuality) {
  return switch (format) {
    'jpeg' => img.encodeJpg(image, quality: jpegQuality),
    _ => img.encodePng(image),
  };
}

({img.Image image, double scale}) downscaleForPreview(
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

int scalePositiveInt(int value, double scale) {
  if (value <= 0) {
    return value;
  }
  return math.max(1, (value * scale).round());
}

Future<ui.Image> decodeUiImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<Uint8List> encodeUiImage(
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

double calculateExportScale(int width, int height) {
  const targetLongEdge = 4096.0;
  const maxScale = 2.0;
  final longestEdge = math.max(width, height).toDouble();
  if (longestEdge >= targetLongEdge) {
    return 1.0;
  }
  return math.min(maxScale, targetLongEdge / longestEdge);
}

int scaleDimension(num value, double scale) =>
    math.max(1, (value * scale).round());

int scalePosition(num value, double scale) =>
    math.max(0, (value * scale).round());
