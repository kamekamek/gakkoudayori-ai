import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// フロントエンド用ユーザー辞書サービス
/// バックエンドのユーザー辞書APIと連携して文字起こし結果を修正
class UserDictionaryService {
  static String get _baseUrl {
    return AppConfig.apiBaseUrl.replaceAll('/api/v1/ai', '');
  }

  /// 文字起こし結果をユーザー辞書で修正
  ///
  /// Args:
  ///   transcript: 音声認識結果のテキスト
  ///   userId: ユーザーID（デフォルト: "default"）
  ///
  /// Returns:
  ///   修正後のテキストと修正詳細
  Future<UserDictionaryCorrectionResult> correctTranscription({
    required String transcript,
    String userId = 'default',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/dictionary/$userId/correct'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'transcript': transcript,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return UserDictionaryCorrectionResult(
          success: true,
          correctedText: data['data']['corrected_text'],
          originalText: data['data']['original_text'],
          corrections: List<Map<String, dynamic>>.from(
              data['data']['corrections'] ?? []),
          processingTimeMs: data['data']['processing_time_ms'] ?? 0,
        );
      } else {
        return UserDictionaryCorrectionResult(
          success: false,
          error: data['error'] ?? 'Unknown error',
          originalText: transcript,
          correctedText: transcript,
        );
      }
    } catch (e) {
      return UserDictionaryCorrectionResult(
        success: false,
        error: 'Network error: $e',
        originalText: transcript,
        correctedText: transcript,
      );
    }
  }

  /// 手動修正を記録（学習用）
  ///
  /// Args:
  ///   original: 修正前のテキスト
  ///   corrected: 修正後のテキスト
  ///   userId: ユーザーID
  ///   context: 修正のコンテキスト
  Future<bool> recordManualCorrection({
    required String original,
    required String corrected,
    String userId = 'default',
    String context = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/dictionary/$userId/learn'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'original': original,
          'corrected': corrected,
          'context': context,
        }),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print('手動修正記録エラー: $e');
      return false;
    }
  }

  /// ユーザー辞書統計情報を取得
  Future<Map<String, dynamic>?> getDictionaryStats({
    String userId = 'default',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/dictionary/$userId/stats'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      }
      return null;
    } catch (e) {
      print('辞書統計取得エラー: $e');
      return null;
    }
  }
}

/// ユーザー辞書修正結果
class UserDictionaryCorrectionResult {
  final bool success;
  final String correctedText;
  final String originalText;
  final List<Map<String, dynamic>> corrections;
  final int processingTimeMs;
  final String? error;

  UserDictionaryCorrectionResult({
    required this.success,
    required this.correctedText,
    required this.originalText,
    this.corrections = const [],
    this.processingTimeMs = 0,
    this.error,
  });

  /// 修正が行われたかどうか
  bool get hasCorrections => corrections.isNotEmpty;

  /// 修正数
  int get correctionCount => corrections.length;

  /// 修正詳細の文字列表現
  String get correctionsDescription {
    if (!hasCorrections) return '修正なし';

    return corrections.map((correction) {
      return '${correction['original']} → ${correction['corrected']}';
    }).join(', ');
  }
}
