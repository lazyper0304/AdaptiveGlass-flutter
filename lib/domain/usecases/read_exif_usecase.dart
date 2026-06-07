library;

import 'package:either_dart/either.dart';

import '../../core/errors/failures.dart';
import '../entities/exif_data.dart';

/// 读取 EXIF 的用例实现
class ReadExifUseCaseImpl implements ReadExifUseCase {
  @override
  Future<Either<Failure, ExifData>> call(Uint8List bytes) async {
    // TODO: 实现实际的 EXIF 读取逻辑
    return const Right(ExifData());
  }
}
