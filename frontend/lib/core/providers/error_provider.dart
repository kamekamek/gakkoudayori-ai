import 'package:flutter/foundation.dart';
import '../exceptions/app_exceptions.dart';

/// エラー情報を保持するクラス
class ErrorInfo {
  final AppException exception;
  final DateTime timestamp;
  final String? context;
  final bool isDismissed;
  final int retryCount;

  ErrorInfo({
    required this.exception,
    required this.timestamp,
    this.context,
    this.isDismissed = false,
    this.retryCount = 0,
  });

  ErrorInfo copyWith({
    AppException? exception,
    DateTime? timestamp,
    String? context,
    bool? isDismissed,
    int? retryCount,
  }) {
    return ErrorInfo(
      exception: exception ?? this.exception,
      timestamp: timestamp ?? this.timestamp,
      context: context ?? this.context,
      isDismissed: isDismissed ?? this.isDismissed,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// 全体的なエラー状態を管理するプロバイダー
class ErrorProvider extends ChangeNotifier {
  final List<ErrorInfo> _errors = [];
  final int _maxErrors = 50; // 保持する最大エラー数
  
  // 現在のエラー状態
  ErrorInfo? _currentError;
  bool _isRetrying = false;
  
  // リトライ設定
  final int maxRetries = 3;
  final Duration retryDelay = const Duration(seconds: 2);
  
  // ゲッター
  List<ErrorInfo> get errors => List.unmodifiable(_errors);
  ErrorInfo? get currentError => _currentError;
  bool get hasErrors => _errors.isNotEmpty;
  bool get hasCriticalErrors => _errors.any((e) => e.exception.severity >= 4);
  bool get isRetrying => _isRetrying;
  
  /// エラーを報告
  void reportError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    bool showToUser = true,
  }) {
    final exception = _convertToAppException(error, stackTrace);
    final errorInfo = ErrorInfo(
      exception: exception,
      timestamp: DateTime.now(),
      context: context,
    );
    
    // エラーリストに追加
    _errors.insert(0, errorInfo);
    
    // 最大数を超えたら古いエラーを削除
    if (_errors.length > _maxErrors) {
      _errors.removeRange(_maxErrors, _errors.length);
    }
    
    // ユーザーに表示すべきエラーの場合、currentErrorに設定
    if (showToUser && (exception.severity >= 2)) {
      _currentError = errorInfo;
    }
    
    // デバッグ出力
    debugPrint('[ErrorProvider] Error reported: ${exception.errorType}');
    debugPrint('[ErrorProvider] Message: ${exception.message}');
    if (context != null) {
      debugPrint('[ErrorProvider] Context: $context');
    }
    
    notifyListeners();
  }
  
  /// エラーをクリア
  void clearError() {
    _currentError = null;
    notifyListeners();
  }
  
  /// 特定のエラーを解除
  void dismissError(ErrorInfo errorInfo) {
    final index = _errors.indexOf(errorInfo);
    if (index != -1) {
      _errors[index] = errorInfo.copyWith(isDismissed: true);
      if (_currentError == errorInfo) {
        _currentError = null;
      }
      notifyListeners();
    }
  }
  
  /// 全てのエラーをクリア
  void clearAllErrors() {
    _errors.clear();
    _currentError = null;
    notifyListeners();
  }
  
  /// リトライ処理を実行
  Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    String? context,
    bool exponentialBackoff = true,
  }) async {
    _isRetrying = true;
    notifyListeners();
    
    try {
      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          final result = await operation();
          debugPrint('[ErrorProvider] Operation succeeded on attempt ${attempt + 1}');
          return result;
        } catch (error, stackTrace) {
          debugPrint('[ErrorProvider] Operation failed on attempt ${attempt + 1}: $error');
          
          if (attempt == maxRetries) {
            // 最後の試行で失敗した場合、エラーを報告
            reportError(
              error,
              stackTrace: stackTrace,
              context: context,
            );
            rethrow;
          }
          
          // リトライ可能でない場合は即座に失敗
          if (!isRetryableError(error)) {
            reportError(
              error,
              stackTrace: stackTrace,
              context: context,
            );
            rethrow;
          }
          
          // 遅延してリトライ
          final delay = exponentialBackoff
              ? Duration(milliseconds: retryDelay.inMilliseconds * (1 << attempt))
              : retryDelay;
          await Future.delayed(delay);
        }
      }
      
      throw StateError('Retry loop completed unexpectedly');
    } finally {
      _isRetrying = false;
      notifyListeners();
    }
  }
  
  /// エラー統計を取得
  Map<String, int> getErrorStatistics() {
    final stats = <String, int>{};
    for (final error in _errors) {
      final type = error.exception.errorType;
      stats[type] = (stats[type] ?? 0) + 1;
    }
    return stats;
  }
  
  /// 最近のエラーを取得（指定時間内）
  List<ErrorInfo> getRecentErrors({Duration? within}) {
    final threshold = within ?? const Duration(hours: 1);
    final cutoff = DateTime.now().subtract(threshold);
    
    return _errors.where((error) => error.timestamp.isAfter(cutoff)).toList();
  }
  
  /// クリティカルエラーを取得
  List<ErrorInfo> getCriticalErrors() {
    return _errors.where((error) => error.exception.severity >= 4).toList();
  }
  
  /// エラーをAppExceptionに変換
  AppException _convertToAppException(dynamic error, StackTrace? stackTrace) {
    if (error is AppException) {
      return error;
    }
    
    // 一般的なエラーを分類
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network')) {
      return NetworkException(
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    
    if (errorString.contains('permission') ||
        errorString.contains('access denied')) {
      return PermissionException(
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    
    // デフォルトは一般的なAppException
    return ApiException(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }
  
  /// エラーレベルに基づく色を取得
  int getErrorColor(ErrorInfo errorInfo) {
    switch (errorInfo.exception.severity) {
      case 1: // info
        return 0xFF2196F3; // blue
      case 2: // warning
        return 0xFFFF9800; // orange
      case 3: // error
        return 0xFFF44336; // red
      case 4: // critical
        return 0xFF9C27B0; // purple
      default:
        return 0xFF757575; // grey
    }
  }
  
  /// エラーレベルに基づくアイコンを取得
  String getErrorIcon(ErrorInfo errorInfo) {
    switch (errorInfo.exception.severity) {
      case 1: // info
        return '💡';
      case 2: // warning
        return '⚠️';
      case 3: // error
        return '❌';
      case 4: // critical
        return '🚨';
      default:
        return '❓';
    }
  }
  
  /// デバッグ情報を取得
  Map<String, dynamic> getDebugInfo() {
    return {
      'total_errors': _errors.length,
      'current_error': _currentError?.exception.errorType,
      'critical_errors': getCriticalErrors().length,
      'is_retrying': _isRetrying,
      'error_statistics': getErrorStatistics(),
      'recent_errors_count': getRecentErrors().length,
    };
  }
  
  /// エラーログをエクスポート
  String exportErrorLog() {
    final buffer = StringBuffer();
    buffer.writeln('=== Error Log Export ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Errors: ${_errors.length}');
    buffer.writeln();
    
    for (final error in _errors) {
      buffer.writeln('--- Error ${_errors.indexOf(error) + 1} ---');
      buffer.writeln('Timestamp: ${error.timestamp.toIso8601String()}');
      buffer.writeln('Type: ${error.exception.errorType}');
      buffer.writeln('Severity: ${error.exception.severity}');
      buffer.writeln('Message: ${error.exception.message}');
      if (error.exception.code != null) {
        buffer.writeln('Code: ${error.exception.code}');
      }
      if (error.context != null) {
        buffer.writeln('Context: ${error.context}');
      }
      buffer.writeln('Retry Count: ${error.retryCount}');
      buffer.writeln('Dismissed: ${error.isDismissed}');
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}