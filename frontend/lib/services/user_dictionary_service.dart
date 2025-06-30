import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// フロントエンド用ユーザー辞書サービス
/// バックエンドのユーザー辞書APIと連携して文字起こし結果を修正
/// ユーザー辞書の単語エントリモデル
class UserDictionaryEntry {
  final String term;
  final List<String> variations;

  UserDictionaryEntry({
    required this.term,
    required this.variations,
  });

  factory UserDictionaryEntry.fromJson(Map<String, dynamic> json) {
    return UserDictionaryEntry(
      term: json['term'] as String,
      variations: List<String>.from(json['variations'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'term': term,
      'variations': variations,
    };
  }
}

class UserDictionaryService {
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
        Uri.parse('${AppConfig.apiV1BaseUrl}/dictionary/$userId/correct'),
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
        Uri.parse('${AppConfig.apiV1BaseUrl}/dictionary/$userId/learn'),
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
      // エラー時のみログ出力
      if (kDebugMode) debugPrint('手動修正記録エラー: $e');
      return false;
    }
  }

  /// ユーザー辞書の用語一覧を取得
  Future<List<UserDictionaryEntry>> getTerms(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiV1BaseUrl}/dictionary/$userId'),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['success'] == true && responseBody['data'] is Map) {
          final apiData = responseBody['data'] as Map<String, dynamic>;
          if (apiData['dictionary'] is Map) {
            final Map<String, dynamic> dictionaryMap =
                apiData['dictionary'] as Map<String, dynamic>;
            final List<UserDictionaryEntry> terms = [];

            // より安全なアプローチでエントリを処理
            for (final entry in dictionaryMap.entries) {
              try {
                final key = entry.key;
                final value = entry.value;

                // キーがnullまたは空文字の場合はスキップ
                if (key == null || key.toString().isEmpty) {
                  continue;
                }

                final termString = key.toString();
                List<String> cleanVariations = [];

                if (value is Map<String, dynamic>) {
                  // カスタム用語の場合（辞書形式）
                  final variations = value['variations'];
                  if (variations is List) {
                    cleanVariations = _extractCleanStringList(variations);
                  }
                } else if (value is List) {
                  // デフォルト用語の場合（配列形式）
                  cleanVariations = _extractCleanStringList(value);
                } else {
                  continue;
                }

                // 有効なバリエーションがある場合のみ追加
                if (cleanVariations.isNotEmpty) {
                  final entry = UserDictionaryEntry(
                    term: termString,
                    variations: cleanVariations,
                  );

                  terms.add(entry);
                }
              } catch (e) {
                // エラー時のみログ出力
                if (kDebugMode) {
                  debugPrint('辞書エントリ処理エラー: $e');
                }
              }
            }
            return terms;
          }
        }
      }

      // エラー時のみログ出力
      if (kDebugMode) {
        debugPrint('辞書取得失敗 - Status: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      // エラー時のみログ出力
      if (kDebugMode) {
        debugPrint('辞書取得エラー: $e');
      }
      return [];
    }
  }

  /// ユーザー辞書に新しい用語を追加
  Future<bool> addTerm(String userId, UserDictionaryEntry entry) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiV1BaseUrl}/dictionary/$userId/terms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(entry.toJson()),
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('用語追加エラー: $e');
      }
      return false;
    }
  }

  /// ユーザー辞書の既存の用語を更新
  Future<bool> updateTerm(
      String userId, String originalTerm, UserDictionaryEntry entry) async {
    try {
      final response = await http.put(
        Uri.parse(
            '${AppConfig.apiV1BaseUrl}/dictionary/$userId/terms/$originalTerm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(entry.toJson()),
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('用語更新エラー: $e');
      }
      return false;
    }
  }

  /// ユーザー辞書から用語を削除
  Future<bool> deleteTerm(String userId, String term) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.apiV1BaseUrl}/dictionary/$userId/terms/$term'),
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('用語削除エラー: $e');
      }
      return false;
    }
  }

  /// Listからnull値を除外してString型のみを安全に抽出
  List<String> _extractCleanStringList(List list) {
    final cleanList = <String>[];

    for (final item in list) {
      if (item != null) {
        try {
          final stringItem = item.toString();
          if (stringItem.isNotEmpty) {
            cleanList.add(stringItem);
          }
        } catch (e) {
          // エラー時のみログ出力
          if (kDebugMode) {
            debugPrint('文字列変換エラー: $item ($e)');
          }
        }
      }
    }

    return cleanList;
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
