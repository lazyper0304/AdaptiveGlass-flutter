library;

/// EXIF 工具类
class ExifUtils {
  ExifUtils._();

  /// 从标签列表中查找并提取可打印值
  static String extractPrintable(
    dynamic tags,
    List<String> keys,
  ) {
    final tag = _findTag(tags, keys);
    return tag?.printable.trim() ?? '';
  }

  /// 提取曝光时间
  static String extractExposure(dynamic tags) {
    final tag = _findTag(tags, const ['EXIF ExposureTime']);
    if (tag == null) return '';

    final values = tag.values.toList();
    if (values.isNotEmpty && values.first is Ratio) {
      final ratio = values.first as Ratio;
      if (ratio.denominator == 0) return '';

      if (ratio.numerator >= ratio.denominator) {
        return _trimDecimal(ratio.toDouble());
      }
      return '${ratio.numerator}/${ratio.denominator}';
    }
    return tag.printable.trim();
  }

  /// 提取比例值为小数
  static String extractRatioAsDecimal(
    dynamic tags,
    List<String> keys,
  ) {
    final tag = _findTag(tags, keys);
    if (tag == null) return '';

    final values = tag.values.toList();
    if (values.isNotEmpty && values.first is Ratio) {
      final ratio = values.first as Ratio;
      if (ratio.denominator == 0) return '';

      return _trimDecimal(ratio.toDouble());
    }
    return tag.printable.trim();
  }

  static String _trimDecimal(double value) {
    final raw = value.toStringAsFixed(1);
    return raw.endsWith('.0') ? raw.substring(0, raw.length - 2) : raw;
  }

  static dynamic _findTag(dynamic tags, List<String> keys) {
    for (final key in keys) {
      final direct = tags[key];
      if (direct != null) return direct;
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
}
