library;

import 'package:either_dart/either.dart';

import '../entities/image_processing_result.dart';
import '../entities/processing_settings.dart';
import '../entities/palette_entry.dart';
import '../entities/exif_data.dart';
import '../../core/errors/failures.dart';

/// 处理图像的用例
abstract class ProcessImageUseCase {
  Future<Either<Failure, ImageProcessingResult>> call({
    required Uint8List bytes,
    required ProcessingSettings settings,
  });
}

/// 提取配色板的用例
abstract class ExtractPaletteUseCase {
  Future<Either<Failure, List<PaletteEntry>>> call({
    required Uint8List bytes,
    int count = 5,
  });
}

/// 读取 EXIF 的用例
abstract class ReadExifUseCase {
  Future<Either<Failure, ExifData>> call(Uint8List bytes);
}
