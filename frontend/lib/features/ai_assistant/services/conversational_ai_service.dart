import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../config/app_config.dart';

/// 対話式AI学級通信作成サービス
class ConversationalAIService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  /// 対話セッション開始
  Future<Map<String, dynamic>> startConversation({
    required String audioTranscript,
    String userId = 'default',
    Map<String, dynamic> teacherProfile = const {},
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🤖 対話セッション開始 - トランスクリプト: ${audioTranscript.length}文字');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/conversation/start'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'audio_transcript': audioTranscript,
          'user_id': userId,
          'teacher_profile': teacherProfile,
        }),
      );

      if (kDebugMode) {
        debugPrint('🤖 対話開始レスポンス - ステータス: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint('✅ 対話セッション開始成功 - セッションID: ${data['session_id']}');
        }
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('対話開始API エラー: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 対話セッション開始エラー: $e');
      }
      throw Exception('対話セッション開始に失敗しました: $e');
    }
  }

  /// 対話応答処理
  Future<Map<String, dynamic>> respondToConversation({
    required String sessionId,
    required Map<String, dynamic> userResponse,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🤖 対話応答送信 - セッション: $sessionId');
        debugPrint('📤 ユーザー応答: ${jsonEncode(userResponse)}');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/conversation/$sessionId/respond'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userResponse),
      );

      if (kDebugMode) {
        debugPrint('🤖 対話応答レスポンス - ステータス: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint('✅ 対話応答成功');
        }
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('対話応答API エラー: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 対話応答エラー: $e');
      }
      throw Exception('対話応答に失敗しました: $e');
    }
  }

  /// セッション状態取得
  Future<Map<String, dynamic>> getSessionStatus(String sessionId) async {
    try {
      if (kDebugMode) {
        debugPrint('🤖 セッション状態取得 - セッション: $sessionId');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/conversation/$sessionId/status'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint('✅ セッション状態取得成功');
        }
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('セッション状態API エラー: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ セッション状態取得エラー: $e');
      }
      throw Exception('セッション状態取得に失敗しました: $e');
    }
  }

  /// 対話履歴取得
  Future<Map<String, dynamic>> getConversationHistory(String sessionId) async {
    try {
      if (kDebugMode) {
        debugPrint('🤖 対話履歴取得 - セッション: $sessionId');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/conversation/$sessionId/history'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint('✅ 対話履歴取得成功 - メッセージ数: ${data['conversation_history']?.length ?? 0}');
        }
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('対話履歴API エラー: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 対話履歴取得エラー: $e');
      }
      throw Exception('対話履歴取得に失敗しました: $e');
    }
  }

  /// プレビューURL取得
  String getPreviewUrl(String sessionId) {
    return '$_baseUrl/conversation/$sessionId/preview';
  }

  /// ダウンロードURL取得
  String getDownloadUrl(String sessionId) {
    return '$_baseUrl/download/$sessionId';
  }
}