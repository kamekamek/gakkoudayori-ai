/// 統一エラーハンドリングのためのカスタム例外クラス群
library;

/// 基底例外クラス
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final bool isRetryable;
  final int severity; // 1: info, 2: warning, 3: error, 4: critical

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
    this.isRetryable = false,
    this.severity = 3,
  });

  /// ユーザーフレンドリーなメッセージを取得
  String get userMessage => _getUserMessage();

  /// 開発者向け詳細メッセージ
  String get detailMessage => _getDetailMessage();

  /// エラーの種別を取得
  String get errorType => runtimeType.toString();

  String _getUserMessage() {
    switch (runtimeType) {
      case NetworkException _:
        return 'インターネット接続を確認してください';
      case ApiException _:
        return 'サーバーとの通信でエラーが発生しました';
      case AudioException _:
        return '音声の処理でエラーが発生しました';
      case SessionException _:
        return 'セッションの問題が発生しました';
      case ValidationException _:
        return '入力内容に問題があります';
      default:
        return 'エラーが発生しました';
    }
  }

  String _getDetailMessage() {
    final buffer = StringBuffer();
    buffer.writeln('Error Type: $errorType');
    buffer.writeln('Message: $message');
    if (code != null) buffer.writeln('Code: $code');
    if (originalError != null) buffer.writeln('Original: $originalError');
    return buffer.toString();
  }

  @override
  String toString() => detailMessage;
}

/// ネットワーク関連の例外
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    super.isRetryable = true,
    super.severity = 3,
  });

  factory NetworkException.timeout() {
    return const NetworkException(
      message: 'Connection timeout occurred',
      code: 'NETWORK_TIMEOUT',
      isRetryable: true,
    );
  }

  factory NetworkException.connectionLost() {
    return const NetworkException(
      message: 'Connection lost',
      code: 'CONNECTION_LOST',
      isRetryable: true,
    );
  }

  factory NetworkException.serverUnavailable() {
    return const NetworkException(
      message: 'Server is currently unavailable',
      code: 'SERVER_UNAVAILABLE',
      isRetryable: true,
    );
  }
}

/// API関連の例外
class ApiException extends AppException {
  final int? statusCode;
  final Map<String, dynamic>? responseData;

  const ApiException({
    required super.message,
    this.statusCode,
    this.responseData,
    super.code,
    super.originalError,
    super.stackTrace,
    super.isRetryable = false,
    super.severity = 3,
  });

  factory ApiException.badRequest(String message,
      [Map<String, dynamic>? data]) {
    return ApiException(
      message: message,
      statusCode: 400,
      responseData: data,
      code: 'BAD_REQUEST',
    );
  }

  factory ApiException.unauthorized() {
    return const ApiException(
      message: 'Authentication required',
      statusCode: 401,
      code: 'UNAUTHORIZED',
    );
  }

  factory ApiException.forbidden() {
    return const ApiException(
      message: 'Access forbidden',
      statusCode: 403,
      code: 'FORBIDDEN',
    );
  }

  factory ApiException.notFound() {
    return const ApiException(
      message: 'Resource not found',
      statusCode: 404,
      code: 'NOT_FOUND',
    );
  }

  factory ApiException.serverError([String? message]) {
    return ApiException(
      message: message ?? 'Internal server error',
      statusCode: 500,
      code: 'SERVER_ERROR',
      isRetryable: true,
    );
  }

  @override
  String get userMessage {
    switch (statusCode) {
      case 400:
        return '入力内容に問題があります';
      case 401:
        return 'ログインが必要です';
      case 403:
        return 'アクセス権限がありません';
      case 404:
        return '要求されたリソースが見つかりません';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'サーバーで問題が発生しています。しばらく待ってから再試行してください';
      default:
        return 'サーバーとの通信でエラーが発生しました';
    }
  }
}

/// 音声処理関連の例外
class AudioException extends AppException {
  const AudioException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    super.isRetryable = true,
    super.severity = 2,
  });

  factory AudioException.permissionDenied() {
    return const AudioException(
      message: 'Microphone permission denied',
      code: 'PERMISSION_DENIED',
      isRetryable: false,
    );
  }

  factory AudioException.notSupported() {
    return const AudioException(
      message: 'Audio recording not supported',
      code: 'NOT_SUPPORTED',
      isRetryable: false,
    );
  }

  factory AudioException.recordingFailed(dynamic error) {
    return AudioException(
      message: 'Audio recording failed',
      code: 'RECORDING_FAILED',
      originalError: error,
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'PERMISSION_DENIED':
        return 'マイクの使用許可が必要です';
      case 'NOT_SUPPORTED':
        return 'このブラウザでは音声録音がサポートされていません';
      case 'RECORDING_FAILED':
        return '音声の録音に失敗しました';
      default:
        return '音声の処理でエラーが発生しました';
    }
  }
}

/// セッション関連の例外
class SessionException extends AppException {
  const SessionException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    super.isRetryable = true,
    super.severity = 2,
  });

  factory SessionException.expired() {
    return const SessionException(
      message: 'Session has expired',
      code: 'SESSION_EXPIRED',
      isRetryable: false,
    );
  }

  factory SessionException.notFound() {
    return const SessionException(
      message: 'Session not found',
      code: 'SESSION_NOT_FOUND',
    );
  }

  factory SessionException.corruptedData() {
    return const SessionException(
      message: 'Session data is corrupted',
      code: 'CORRUPTED_DATA',
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'SESSION_EXPIRED':
        return 'セッションの有効期限が切れました。再開してください';
      case 'SESSION_NOT_FOUND':
        return 'セッションが見つかりません';
      case 'CORRUPTED_DATA':
        return 'セッションデータが破損しています';
      default:
        return 'セッションで問題が発生しました';
    }
  }
}

/// バリデーション関連の例外
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.message,
    this.fieldErrors,
    super.code,
    super.originalError,
    super.stackTrace,
    super.isRetryable = false,
    super.severity = 2,
  });

  factory ValidationException.required(String field) {
    return ValidationException(
      message: '$field is required',
      code: 'FIELD_REQUIRED',
      fieldErrors: {field: '必須項目です'},
    );
  }

  factory ValidationException.invalidFormat(String field, String format) {
    return ValidationException(
      message: '$field has invalid format: $format',
      code: 'INVALID_FORMAT',
      fieldErrors: {field: '形式が正しくありません'},
    );
  }

  @override
  String get userMessage {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      return fieldErrors!.values.first;
    }
    return '入力内容に問題があります';
  }
}

/// コンテンツ処理関連の例外
class ContentException extends AppException {
  const ContentException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    super.isRetryable = true,
    super.severity = 2,
  });

  factory ContentException.generationFailed([String? reason]) {
    return ContentException(
      message: 'Content generation failed${reason != null ? ': $reason' : ''}',
      code: 'GENERATION_FAILED',
    );
  }

  factory ContentException.parsingFailed(dynamic error) {
    return ContentException(
      message: 'Content parsing failed',
      code: 'PARSING_FAILED',
      originalError: error,
    );
  }

  factory ContentException.invalidFormat() {
    return const ContentException(
      message: 'Invalid content format',
      code: 'INVALID_FORMAT',
      isRetryable: false,
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'GENERATION_FAILED':
        return 'コンテンツの生成に失敗しました';
      case 'PARSING_FAILED':
        return 'コンテンツの解析に失敗しました';
      case 'INVALID_FORMAT':
        return 'コンテンツの形式が正しくありません';
      default:
        return 'コンテンツの処理でエラーが発生しました';
    }
  }
}

/// 権限関連の例外
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    super.isRetryable = false,
    super.severity = 3,
  });

  factory PermissionException.microphoneDenied() {
    return const PermissionException(
      message: 'Microphone permission denied',
      code: 'MICROPHONE_DENIED',
    );
  }

  factory PermissionException.storageAccessDenied() {
    return const PermissionException(
      message: 'Storage access denied',
      code: 'STORAGE_DENIED',
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'MICROPHONE_DENIED':
        return 'マイクの使用許可が必要です。ブラウザの設定を確認してください';
      case 'STORAGE_DENIED':
        return 'ストレージアクセスの許可が必要です';
      default:
        return 'アクセス権限の問題が発生しました';
    }
  }
}

/// リトライ可能なエラーかどうかを判定するヘルパー関数
bool isRetryableError(dynamic error) {
  if (error is AppException) {
    return error.isRetryable;
  }

  // 一般的なネットワークエラーはリトライ可能
  final errorString = error.toString().toLowerCase();
  return errorString.contains('timeout') ||
      errorString.contains('connection') ||
      errorString.contains('network') ||
      errorString.contains('socket');
}

/// エラーの重要度を取得するヘルパー関数
int getErrorSeverity(dynamic error) {
  if (error is AppException) {
    return error.severity;
  }
  return 3; // デフォルトはerror
}

/// エラーからユーザーメッセージを取得するヘルパー関数
String getUserMessageFromError(dynamic error) {
  if (error is AppException) {
    return error.userMessage;
  }
  return 'エラーが発生しました';
}
