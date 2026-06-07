library;

import 'package:either_dart/either.dart';

import '../entities/image_processing_result.dart';
import '../entities/processing_settings.dart';
import '../entities/palette_entry.dart';
import '../entities/exif_data.dart';
import '../../core/errors/failures.dart';

/// 图像仓库接口
abstract class ImageRepository {
  /// 处理图像
  Future<Either<Failure, ImageProcessingResult>> processImage({
    required Uint8List bytes,
    required ProcessingSettings settings,
  });

  /// 提取配色板
  Future<Either<Failure, List<PaletteEntry>>> extractPalette({
    required Uint8List bytes,
    int count = 5,
  });

  /// 读取 EXIF 数据
  Future<Either<Failure, ExifData>> readExif(Uint8List bytes);
}
