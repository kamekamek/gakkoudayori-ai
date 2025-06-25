import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../exceptions/app_exceptions.dart';
import '../providers/error_provider.dart';

/// セッション復旧のためのデータクラス
class SessionRecoveryData {
  final String sessionId;
  final String userId;
  final List<Map<String, dynamic>> messages;
  final String? generatedHtml;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  SessionRecoveryData({
    required this.sessionId,
    required this.userId,
    required this.messages,
    this.generatedHtml,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'messages': messages,
      'generated_html': generatedHtml,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory SessionRecoveryData.fromJson(Map<String, dynamic> json) {
    return SessionRecoveryData(
      sessionId: json['session_id'],
      userId: json['user_id'],
      messages: List<Map<String, dynamic>>.from(json['messages'] ?? []),
      generatedHtml: json['generated_html'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }
}

/// セッション復旧サービス
class SessionRecoveryService {
  final ErrorProvider _errorProvider;
  static const String _storageKey = 'adk_session_recovery';
  static const Duration _maxRecoveryAge = Duration(hours: 24);

  SessionRecoveryService({required ErrorProvider errorProvider})
      : _errorProvider = errorProvider;

  /// セッションデータを保存
  Future<bool> saveSessionData(SessionRecoveryData data) async {
    try {
      if (!kIsWeb) {
        debugPrint('[SessionRecovery] Non-web platform, skipping save');
        return false;
      }

      final jsonString = jsonEncode(data.toJson());
      html.window.localStorage[_storageKey] = jsonString;
      
      debugPrint('[SessionRecovery] Session data saved for ${data.sessionId}');
      return true;
    } catch (error, stackTrace) {
      _errorProvider.reportError(
        SessionException(
          message: 'Failed to save session data',
          code: 'SAVE_FAILED',
          originalError: error,
          stackTrace: stackTrace,
        ),
        context: 'Session data saving',
        showToUser: false,
      );
      return false;
    }
  }

  /// セッションデータを復旧
  Future<SessionRecoveryData?> recoverSessionData() async {
    try {
      if (!kIsWeb) {
        debugPrint('[SessionRecovery] Non-web platform, skipping recovery');
        return null;
      }

      final jsonString = html.window.localStorage[_storageKey];
      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('[SessionRecovery] No session data found');
        return null;
      }

      final json = jsonDecode(jsonString);
      final data = SessionRecoveryData.fromJson(json);

      // データの有効期限をチェック
      if (DateTime.now().difference(data.timestamp) > _maxRecoveryAge) {
        debugPrint('[SessionRecovery] Session data too old, clearing');
        await clearSessionData();
        return null;
      }

      debugPrint('[SessionRecovery] Session data recovered for ${data.sessionId}');
      return data;
    } catch (error, stackTrace) {
      _errorProvider.reportError(
        SessionException.corruptedData(),
        stackTrace: stackTrace,
        context: 'Session data recovery',
        showToUser: false,
      );
      
      // 破損したデータをクリア
      await clearSessionData();
      return null;
    }
  }

  /// セッションデータをクリア
  Future<void> clearSessionData() async {
    try {
      if (!kIsWeb) {
        debugPrint('[SessionRecovery] Non-web platform, skipping clear');
        return;
      }

      html.window.localStorage.remove(_storageKey);
      debugPrint('[SessionRecovery] Session data cleared');
    } catch (error, stackTrace) {
      _errorProvider.reportError(
        SessionException(
          message: 'Failed to clear session data',
          code: 'CLEAR_FAILED',
          originalError: error,
          stackTrace: stackTrace,
        ),
        context: 'Session data clearing',
        showToUser: false,
      );
    }
  }

  /// セッション復旧が可能かチェック
  Future<bool> canRecoverSession() async {
    final data = await recoverSessionData();
    return data != null;
  }

  /// セッションデータのメタデータを取得
  Future<Map<String, dynamic>?> getSessionMetadata() async {
    try {
      if (!kIsWeb) return null;

      final jsonString = html.window.localStorage[_storageKey];
      if (jsonString == null || jsonString.isEmpty) return null;

      final json = jsonDecode(jsonString);
      return {
        'session_id': json['session_id'],
        'user_id': json['user_id'],
        'timestamp': json['timestamp'],
        'message_count': (json['messages'] as List?)?.length ?? 0,
        'has_html': json['generated_html'] != null,
      };
    } catch (error) {
      debugPrint('[SessionRecovery] Error getting metadata: $error');
      return null;
    }
  }

  /// 自動復旧の実行
  Future<SessionRecoveryData?> attemptAutoRecovery() async {
    try {
      debugPrint('[SessionRecovery] Attempting auto recovery...');
      
      final data = await recoverSessionData();
      if (data == null) {
        debugPrint('[SessionRecovery] No data to recover');
        return null;
      }

      // 復旧可能性の検証
      if (!_validateRecoveryData(data)) {
        debugPrint('[SessionRecovery] Recovery data validation failed');
        await clearSessionData();
        return null;
      }

      debugPrint('[SessionRecovery] Auto recovery successful');
      return data;
    } catch (error, stackTrace) {
      _errorProvider.reportError(
        SessionException(
          message: 'Auto recovery failed',
          code: 'AUTO_RECOVERY_FAILED',
          originalError: error,
          stackTrace: stackTrace,
        ),
        context: 'Automatic session recovery',
      );
      return null;
    }
  }

  /// 復旧データの妥当性を検証
  bool _validateRecoveryData(SessionRecoveryData data) {
    try {
      // 必須フィールドの確認
      if (data.sessionId.isEmpty || data.userId.isEmpty) {
        return false;
      }

      // メッセージデータの基本的な妥当性確認
      for (final message in data.messages) {
        if (!message.containsKey('role') || 
            !message.containsKey('content') ||
            !message.containsKey('timestamp')) {
          return false;
        }
      }

      // HTMLコンテンツの基本的な確認
      if (data.generatedHtml != null) {
        if (data.generatedHtml!.isEmpty || 
            !data.generatedHtml!.contains('<') ||
            !data.generatedHtml!.contains('>')) {
          return false;
        }
      }

      return true;
    } catch (error) {
      debugPrint('[SessionRecovery] Validation error: $error');
      return false;
    }
  }

  /// 強制復旧（ユーザー要求時）
  Future<SessionRecoveryData?> forceRecovery() async {
    try {
      debugPrint('[SessionRecovery] Force recovery requested...');
      
      if (!kIsWeb) {
        throw SessionException(
          message: 'Force recovery not supported on this platform',
          code: 'PLATFORM_NOT_SUPPORTED',
        );
      }

      final jsonString = html.window.localStorage[_storageKey];
      if (jsonString == null || jsonString.isEmpty) {
        throw SessionException.notFound();
      }

      final json = jsonDecode(jsonString);
      final data = SessionRecoveryData.fromJson(json);

      debugPrint('[SessionRecovery] Force recovery completed');
      return data;
    } catch (error, stackTrace) {
      _errorProvider.reportError(
        error is AppException ? error : SessionException.corruptedData(),
        stackTrace: stackTrace,
        context: 'Force session recovery',
      );
      rethrow;
    }
  }

  /// セッション復旧のリセット（新しいセッション開始時）
  Future<void> resetForNewSession() async {
    await clearSessionData();
    debugPrint('[SessionRecovery] Reset for new session');
  }

  /// 復旧統計の取得
  Map<String, dynamic> getRecoveryStats() {
    return {
      'storage_key': _storageKey,
      'max_recovery_age_hours': _maxRecoveryAge.inHours,
      'platform_supported': kIsWeb,
      'last_check': DateTime.now().toIso8601String(),
    };
  }
}