import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

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
    required this.compositeBytes,
    required this.backgroundBytes,
    required this.foregroundBytes,
    required this.layoutInfo,
    required this.renderScale,
  });

  final Uint8List compositeBytes;
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

class PaletteSwatch {
  const PaletteSwatch({
    required this.red,
    required this.green,
    required this.blue,
  });

  final int red;
  final int green;
  final int blue;

  String get hexCode =>
      '#${_hex(red)}${_hex(green)}${_hex(blue)}';

  Color toColor() => Color.fromARGB(255, red, green, blue);

  img.ColorRgba8 toImageColor() => img.ColorRgba8(red, green, blue, 255);

  Map<String, int> toJson() {
    return <String, int>{'red': red, 'green': green, 'blue': blue};
  }

  factory PaletteSwatch.fromJson(Map<String, dynamic> json) {
    return PaletteSwatch(
      red: (json['red'] as num).round(),
      green: (json['green'] as num).round(),
      blue: (json['blue'] as num).round(),
    );
  }

  static String _hex(int value) => value.toRadixString(16).padLeft(2, '0').toUpperCase();
}

enum RasterOutputFormat { png, jpeg }
