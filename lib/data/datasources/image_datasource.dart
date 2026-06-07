library;

import 'dart:typed_data';

/// 图像数据源接口
abstract class ImageDatasource {
  /// 从字节数据读取 EXIF
  Future<ExifData> readExif(Uint8List bytes);

  /// 从字节数据提取配色板
  Future<List<PaletteEntry>> extractPalette(Uint8List bytes, {int count = 5});

  /// 解码图片
  dynamic decodeImage(Uint8List bytes);

  /// 编码图片为 JPEG
  Uint8List encodeJpg(dynamic image, {int quality = 95});

  /// 编码图片为 PNG
  Uint8List encodePng(dynamic image);
}
