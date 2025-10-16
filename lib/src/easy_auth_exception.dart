/// EasyAuth异常基类
class EasyAuthException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;
  final StackTrace? stackTrace;

  EasyAuthException(
    this.message, {
    this.statusCode,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('EasyAuthException: $message');
    if (statusCode != null) {
      buffer.write(' (status: $statusCode)');
    }
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    return buffer.toString();
  }
}

/// 网络错误
class NetworkException extends EasyAuthException {
  NetworkException(
    super.message, {
    super.statusCode,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// 认证错误
class AuthenticationException extends EasyAuthException {
  AuthenticationException(
    super.message, {
    super.statusCode,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'AuthenticationException: $message';
}

/// 验证码错误
class VerificationCodeException extends EasyAuthException {
  VerificationCodeException(
    super.message, {
    super.statusCode,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'VerificationCodeException: $message';
}

/// Token过期错误
class TokenExpiredException extends AuthenticationException {
  TokenExpiredException([String message = 'Token has expired'])
    : super(message, statusCode: 401);

  @override
  String toString() => 'TokenExpiredException: $message';
}

/// 配置错误
class ConfigurationException extends EasyAuthException {
  ConfigurationException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'ConfigurationException: $message';
}

/// 平台错误（原生SDK调用失败）
class PlatformException extends EasyAuthException {
  final String? platform;

  PlatformException(
    super.message, {
    this.platform,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('PlatformException: $message');
    if (platform != null) {
      buffer.write(' (platform: $platform)');
    }
    return buffer.toString();
  }
}


