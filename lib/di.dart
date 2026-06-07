import 'package:get_it/get_it.dart';

import '../data/repositories/repositories.dart';
import '../domain/entities/processing_settings.dart';
import '../domain/usecases/usecases.dart';
import '../presentation/features/editor/features/export_manager/export_bloc.dart';

final getIt = GetIt.instance;

/// 初始化依赖注入
void setupDependencies() {
  // 仓库层
  getIt.registerLazySingleton<ImageRepository>(() => ImageRepositoryImpl());

  // 用例层
  // getIt.registerLazySingleton<ProcessImageUseCase>(() => ProcessImageUseCaseImpl(getIt()));
  // getIt.registerLazySingleton<ExtractPaletteUseCase>(() => ExtractPaletteUseCaseImpl(getIt()));
  // getIt.registerLazySingleton<ReadExifUseCase>(() => ReadExifUseCaseImpl(getIt()));

  // BLoC 层
  // getIt.registerFactory(() => ExportBloc());

  // 领域层实体（无状态，不需要注册）
  // getIt.registerLazySingleton<ProcessingSettings>(() => ProcessingSettings());
}
