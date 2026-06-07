library;

import 'dart:typed_data';

/// 图像处理结果
class ImageProcessingResult {
  const ImageProcessingResult({
    required this.imageBytes,
    required this.layoutInfo,
    required this.exif,
  });

  final Uint8List imageBytes;
  final LayoutInfo layoutInfo;
  final ExifData exif;
}

/// 布局信息
class LayoutInfo {
  const LayoutInfo({
    required this.targetWidth,
    required this.targetHeight,
    required this.contentX,
    required this.contentY,
    required this.contentWidth,
    required this.contentHeight,
    this.infoPanelTop = 0,
    this.infoPanelHeight = 0,
  });

  final int targetWidth;
  final int targetHeight;
  final int contentX;
  final int contentY;
  final int contentWidth;
  final int contentHeight;
  final int infoPanelTop;
  final int infoPanelHeight;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayoutInfo &&
          runtimeType == other.runtimeType &&
          targetWidth == other.targetWidth &&
          targetHeight == other.targetHeight &&
          contentX == other.contentX &&
          contentY == other.contentY &&
          contentWidth == other.contentWidth &&
          contentHeight == other.contentHeight &&
          infoPanelTop == other.infoPanelTop &&
          infoPanelHeight == other.infoPanelHeight;

  @override
  int get hashCode => Object.hash(
        targetWidth,
        targetHeight,
        contentX,
        contentY,
        contentWidth,
        contentHeight,
        infoPanelTop,
        infoPanelHeight,
      );

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'target_width': targetWidth,
      'target_height': targetHeight,
      'content_x': contentX,
      'content_y': contentY,
      'content_width': contentWidth,
      'content_height': contentHeight,
      'info_panel_top': infoPanelTop,
      'info_panel_height': infoPanelHeight,
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
      infoPanelTop: (json['info_panel_top'] as num?)?.round() ?? 0,
      infoPanelHeight: (json['info_panel_height'] as num?)?.round() ?? 0,
    );
  }
}

/// EXIF 数据
class ExifData {
  const ExifData({
    this.make = '',
    this.model = '',
    this.iso = '',
    this.exposureTime = '',
    this.fNumber = '',
    this.focalLength = '',
    this.dateTimeOriginal = '',
  });

  final String make;
  final String model;
  final String iso;
  final String exposureTime;
  final String fNumber;
  final String focalLength;
  final String dateTimeOriginal;

  bool get hasData => model.isNotEmpty || make.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExifData &&
          runtimeType == other.runtimeType &&
          make == other.make &&
          model == other.model &&
          iso == other.iso &&
          exposureTime == other.exposureTime &&
          fNumber == other.fNumber &&
          focalLength == other.focalLength &&
          dateTimeOriginal == other.dateTimeOriginal;

  @override
  int get hashCode => Object.hash(
        make,
        model,
        iso,
        exposureTime,
        fNumber,
        focalLength,
        dateTimeOriginal,
      );

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'make': make,
      'model': model,
      'iso': iso,
      'exposureTime': exposureTime,
      'fNumber': fNumber,
      'focalLength': focalLength,
      'dateTimeOriginal': dateTimeOriginal,
    };
  }

  factory ExifData.fromJson(Map<String, dynamic> json) {
    return ExifData(
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      iso: json['iso'] as String? ?? '',
      exposureTime: json['exposureTime'] as String? ?? '',
      fNumber: json['fNumber'] as String? ?? '',
      focalLength: json['focalLength'] as String? ?? '',
      dateTimeOriginal: json['dateTimeOriginal'] as String? ?? '',
    );
  }
}
