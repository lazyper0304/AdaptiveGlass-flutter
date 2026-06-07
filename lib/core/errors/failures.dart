library;

/// 失败类型定义（用于领域层）
abstract class Failure {
  final String message;
  final String? errorCode;

  const Failure({
    required this.message,
    this.errorCode,
  });
}

// 通用失败
class ServerFailure extends Failure {
  const ServerFailure(String message, [String? code])
      : super(message: message, errorCode: code);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message: message);
}

class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message: message);
}

class LocalFailure extends Failure {
  const LocalFailure(String message) : super(message: message);
}

// 领域特定失败
class ImageProcessingFailure extends Failure {
  const ImageProcessingFailure(String message) : super(message: message);
}

class ValidationFailure extends Failure {
  final List<String> fields;

  const ValidationFailure(String message, this.fields)
      : super(message: message);
}
