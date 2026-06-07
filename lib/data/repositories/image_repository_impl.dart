library;

import 'package:either_dart/either.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/image_processing_result.dart';
import '../../domain/entities/processing_settings.dart';
import '../../domain/entities/palette_entry.dart';
import '../../domain/entities/exif_data.dart';

/// 图像仓库实现
class ImageRepositoryImpl implements ImageRepository {
  @override
  Future<Either<Failure, ImageProcessingResult>> processImage({
    required Uint8List bytes,
    required ProcessingSettings settings,
  }) async {
    // TODO: 实现实际的图像处理逻辑，调用渲染器
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

  @override
  Future<Either<Failure, List<PaletteEntry>>> extractPalette({
    required Uint8List bytes,
    int count = 5,
  }) async {
    // TODO: 实现实际的配色提取逻辑
    return const Right([]);
  }

  @override
  Future<Either<Failure, ExifData>> readExif(Uint8List bytes) async {
    // TODO: 实现实际的 EXIF 读取逻辑
    return const Right(ExifData());
  }
}
