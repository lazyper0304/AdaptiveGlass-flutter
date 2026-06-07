library;

import 'package:either_dart/either.dart';

import '../../core/errors/failures.dart';
import '../entities/palette_entry.dart';

/// 提取配色板的用例实现
class ExtractPaletteUseCaseImpl implements ExtractPaletteUseCase {
  @override
  Future<Either<Failure, List<PaletteEntry>>> call({
    required Uint8List bytes,
    int count = 5,
  }) async {
    // TODO: 实现实际的配色提取逻辑
    return const Right([]);
  }
}
