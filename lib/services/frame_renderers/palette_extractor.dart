import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

import '../frame_processing_models.dart';

class PaletteBucket {
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

List<PaletteSwatch> extractPaletteSwatches(
  img.Image image, {
  required int count,
}) {
  final sampled = img.copyResize(
    image,
    width: 72,
    height: math.max(1, (image.height * (72 / image.width)).round()),
    interpolation: img.Interpolation.linear,
  );
  final buckets = <int, PaletteBucket>{};

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
    buckets.putIfAbsent(key, PaletteBucket.new).add(r, g, b, weight);
  }

  return buildPaletteFromBuckets(buckets, count: count);
}

List<PaletteSwatch> buildPaletteFromBuckets(
  Map<int, PaletteBucket> buckets, {
  required int count,
}) {
  final sorted = buckets.values.toList()
    ..sort((a, b) => b.weight.compareTo(a.weight));

  final palette = <PaletteSwatch>[];
  for (final bucket in sorted) {
    final candidate = bucket.toColor();
    if (palette.every((color) => colorDistance(color, candidate) >= 84)) {
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

int colorDistance(PaletteSwatch left, PaletteSwatch right) {
  return ((left.red - right.red).abs() +
          (left.green - right.green).abs() +
          (left.blue - right.blue).abs())
      .round();
}

List<Map<String, int>> extractPaletteTask(Map<String, Object?> input) {
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
  return extractPaletteSwatches(
    source,
    count: count,
  ).map((item) => item.toJson()).toList();
}

Future<List<PaletteSwatch>> extractPaletteWithUiCodec(
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
        return extractPaletteSwatchesFromRgba(
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

List<PaletteSwatch> extractPaletteSwatchesFromRgba(
  Uint8List rgbaBytes, {
  required int width,
  required int height,
  required int count,
}) {
  final buckets = <int, PaletteBucket>{};
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
    buckets.putIfAbsent(key, PaletteBucket.new).add(r, g, b, weight);
  }

  return buildPaletteFromBuckets(buckets, count: count);
}
