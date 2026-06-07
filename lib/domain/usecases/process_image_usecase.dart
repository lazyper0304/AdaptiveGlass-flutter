library;

import 'package:either_dart/either.dart';

import '../../core/errors/failures.dart';
import '../entities/image_processing_result.dart';
import '../entities/processing_settings.dart';
import '../entities/palette_entry.dart';
import '../entities/exif_data.dart';

/// 处理图像的用例实现
class ProcessImageUseCaseImpl implements ProcessImageUseCase {
  @override
  Future<Either<Failure, ImageProcessingResult>> call({
    required Uint8List bytes,
    required ProcessingSettings settings,
  }) async {
    // TODO: 实现实际的图像处理逻辑
    return Right(
      ImageProcessingResult(
        imageBytes: bytes,
        layoutInfo: const LayoutInfo(
          targetWidth: 0,
          targetHeight: 0,
          contentX: 0,
          contentY: 0,
          contentWidth: 0,
          contentHeight: 0,
        ),
        exif: const ExifData(),
      ),
    );
  }
}
