library;

import 'package:flutter/foundation.dart';

/// 异常定义
class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException({
    required this.message,
    this.cause,
  });

  @override
  String toString() => 'AppException: $message${cause == null ? '' : ' caused by $cause'}';
}

class ImageProcessingException extends AppException {
  const ImageProcessingException(String message, [this.cause])
      : super(message: message);

  final Object? cause;
}

class FileNotFoundError extends AppException {
  const FileNotFoundError(String path)
      : super(message: '文件未找到: $path');
}

class InvalidPresetException extends AppException {
  const InvalidPresetException(String message)
      : super(message: '无效的预设: $message');
}

class ExifParseException extends AppException {
  const ExifParseException(String message)
      : super(message: 'EXIF 解析失败: $message');
}
