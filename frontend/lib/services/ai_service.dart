import 'dart:convert';
import 'package:http/http.dart' as http;

/// Gemini Pro AI文章生成サービス
class AIService {
  static const String _baseUrl = 'http://localhost:8080/api/v1/ai';

  /// 学級通信HTML生成
  Future<AIGenerationResult> generateNewsletter({
    required String transcribedText,
    String templateType = 'daily_report',
    bool includeGreeting = true,
    String targetAudience = 'parents',
    String season = 'auto',
    String customInstruction = '',
  }) async {
    try {
      print(
          '🤖 AI生成開始 - テキスト: ${transcribedText.substring(0, transcribedText.length > 50 ? 50 : transcribedText.length)}...');

      final response = await http.post(
        Uri.parse('$_baseUrl/generate-newsletter'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'transcribed_text': transcribedText,
          'template_type': templateType,
          'include_greeting': includeGreeting,
          'target_audience': targetAudience,
          'season': season,
          'custom_instruction': customInstruction,
        }),
      );

      print('🤖 AI生成レスポンス - ステータス: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final result = AIGenerationResult.fromJson(data['data']);
          print(
              '✅ AI生成成功 - 文字数: ${result.characterCount}文字, 時間: ${result.processingTimeMs}ms');
          return result;
        } else {
          throw Exception(data['error'] ?? 'Unknown AI generation error');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('API Error: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ AI生成エラー: $e');
      throw Exception('AI文章生成に失敗しました: $e');
    }
  }

  /// カスタムHTML生成（汎用版）
  Future<String> generateCustomHTML({
    required String transcribedText,
    String customInstruction = '',
    String seasonTheme = '',
    String documentType = 'class_newsletter',
    Map<String, dynamic> constraints = const {},
  }) async {
    try {
      print('🤖 カスタムHTML生成開始');

      final response = await http.post(
        Uri.parse('$_baseUrl/generate-html'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'transcribed_text': transcribedText,
          'custom_instruction': customInstruction,
          'season_theme': seasonTheme,
          'document_type': documentType,
          'constraints': constraints,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return data['data']['html_content'];
        } else {
          throw Exception(data['error'] ?? 'HTML generation failed');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('API Error: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ カスタムHTML生成エラー: $e');
      throw Exception('HTML生成に失敗しました: $e');
    }
  }
}

/// AI生成結果データクラス
class AIGenerationResult {
  final String newsletterHtml;
  final String originalSpeech;
  final String templateType;
  final String season;
  final int processingTimeMs;
  final DateTime generatedAt;
  final int wordCount;
  final int characterCount;
  final Map<String, dynamic> aiMetadata;

  AIGenerationResult({
    required this.newsletterHtml,
    required this.originalSpeech,
    required this.templateType,
    required this.season,
    required this.processingTimeMs,
    required this.generatedAt,
    required this.wordCount,
    required this.characterCount,
    required this.aiMetadata,
  });

  factory AIGenerationResult.fromJson(Map<String, dynamic> json) {
    return AIGenerationResult(
      newsletterHtml: json['newsletter_html'] ?? '',
      originalSpeech: json['original_speech'] ?? '',
      templateType: json['template_type'] ?? 'daily_report',
      season: json['season'] ?? 'auto',
      processingTimeMs: json['processing_time_ms'] ?? 0,
      generatedAt: DateTime.parse(
          json['generated_at'] ?? DateTime.now().toIso8601String()),
      wordCount: json['word_count'] ?? 0,
      characterCount: json['character_count'] ?? 0,
      aiMetadata: json['ai_metadata'] ?? {},
    );
  }

  /// 品質スコア計算（文字数ベース）
  String get qualityScore {
    if (characterCount > 1000) return '高品質';
    if (characterCount > 500) return '標準';
    return '要改善';
  }

  /// 生成時間の可読表示
  String get processingTimeDisplay {
    if (processingTimeMs < 1000) {
      return '${processingTimeMs}ms';
    } else {
      return '${(processingTimeMs / 1000).toStringAsFixed(1)}秒';
    }
  }
}
