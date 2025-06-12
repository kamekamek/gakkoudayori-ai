import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Gemini AI統合サービス
/// 
/// 音声認識からHTML生成までの完全なAIフローを提供します
class AiService {
  static const String _baseUrl = 'http://localhost:8081';
  
  /// 音声認識結果
  static const String _transcribeEndpoint = '/api/v1/ai/transcribe';
  
  /// HTML生成エンドポイント
  static const String _generateHtmlEndpoint = '/api/v1/ai/generate-html';
  
  /// 学級通信生成エンドポイント（統合版）
  static const String _generateNewsletterEndpoint = '/api/v1/ai/generate-newsletter';

  /// 音声ファイルを文字起こし
  /// 
  /// [audioBytes] 音声データ
  /// [language] 言語コード (デフォルト: 'ja-JP')
  /// [userDictionary] ユーザー辞書 (カンマ区切り)
  /// 
  /// Returns: 文字起こし結果
  static Future<Map<String, dynamic>> transcribeAudio({
    required Uint8List audioBytes,
    String language = 'ja-JP',
    String? userDictionary,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$_transcribeEndpoint'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'audio_file',
          audioBytes,
          filename: 'audio.wav',
        ),
      );

      request.fields['language'] = language;
      if (userDictionary != null) {
        request.fields['user_dictionary'] = userDictionary;
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      return json.decode(responseData);
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
        'error_code': 'NETWORK_ERROR'
      };
    }
  }

  /// 文字起こし結果からHTML生成
  /// 
  /// [transcribedText] 文字起こし結果
  /// [customInstruction] カスタム指示（オプション）
  /// [seasonTheme] 季節テーマ（オプション）
  /// [documentType] ドキュメントタイプ（デフォルト: 'class_newsletter'）
  /// [constraints] HTML制約（オプション）
  /// 
  /// Returns: HTML生成結果
  static Future<Map<String, dynamic>> generateHtml({
    required String transcribedText,
    String? customInstruction,
    String? seasonTheme,
    String documentType = 'class_newsletter',
    Map<String, dynamic>? constraints,
  }) async {
    try {
      final requestBody = {
        'transcribed_text': transcribedText,
        'document_type': documentType,
      };

      if (customInstruction != null && customInstruction.isNotEmpty) {
        requestBody['custom_instruction'] = customInstruction;
      }
      
      if (seasonTheme != null && seasonTheme.isNotEmpty) {
        requestBody['season_theme'] = seasonTheme;
      }
      
      if (constraints != null) {
        requestBody['constraints'] = json.encode(constraints);
      }

      final response = await http.post(
        Uri.parse('$_baseUrl$_generateHtmlEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
        'error_code': 'NETWORK_ERROR'
      };
    }
  }

  /// 学級通信自動生成（音声→文字起こし→HTML生成の統合版）
  /// 
  /// [transcribedText] 文字起こし結果
  /// [templateType] テンプレートタイプ（デフォルト: 'daily_report'）
  /// [includeGreeting] 挨拶文を含めるか（デフォルト: true）
  /// [targetAudience] 対象読者（デフォルト: 'parents'）
  /// [season] 季節（デフォルト: 'auto'）
  /// [customInstruction] カスタム指示（オプション）
  /// 
  /// Returns: 学級通信生成結果
  static Future<Map<String, dynamic>> generateNewsletter({
    required String transcribedText,
    String templateType = 'daily_report',
    bool includeGreeting = true,
    String targetAudience = 'parents',
    String season = 'auto',
    String? customInstruction,
  }) async {
    try {
      final requestBody = {
        'transcribed_text': transcribedText,
        'template_type': templateType,
        'include_greeting': includeGreeting,
        'target_audience': targetAudience,
        'season': season,
      };

      if (customInstruction != null && customInstruction.isNotEmpty) {
        requestBody['custom_instruction'] = customInstruction;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl$_generateNewsletterEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
        'error_code': 'NETWORK_ERROR'
      };
    }
  }

  /// 音声ファイルから学級通信生成（完全フロー）
  /// 
  /// [audioBytes] 音声データ
  /// [templateType] テンプレートタイプ
  /// [includeGreeting] 挨拶文を含めるか
  /// [targetAudience] 対象読者
  /// [season] 季節
  /// [customInstruction] カスタム指示
  /// [language] 音声認識言語
  /// [userDictionary] ユーザー辞書
  /// 
  /// Returns: 完全フロー結果
  static Future<Map<String, dynamic>> generateNewsletterFromAudio({
    required Uint8List audioBytes,
    String templateType = 'daily_report',
    bool includeGreeting = true,
    String targetAudience = 'parents',
    String season = 'auto',
    String? customInstruction,
    String language = 'ja-JP',
    String? userDictionary,
  }) async {
    try {
      // ステップ1: 音声文字起こし
      final transcribeResult = await transcribeAudio(
        audioBytes: audioBytes,
        language: language,
        userDictionary: userDictionary,
      );

      if (!transcribeResult['success']) {
        return transcribeResult;
      }

      final transcribedText = transcribeResult['data']['transcript'] as String;

      // ステップ2: 学級通信生成
      final newsletterResult = await generateNewsletter(
        transcribedText: transcribedText,
        templateType: templateType,
        includeGreeting: includeGreeting,
        targetAudience: targetAudience,
        season: season,
        customInstruction: customInstruction,
      );

      if (!newsletterResult['success']) {
        return newsletterResult;
      }

      // 統合結果を返す
      return {
        'success': true,
        'data': {
          ...newsletterResult['data'],
          'transcribe_result': transcribeResult['data'],
        }
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Complete flow error: $e',
        'error_code': 'COMPLETE_FLOW_ERROR'
      };
    }
  }

  /// AIサービスのヘルスチェック
  /// 
  /// Returns: サービス状態
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Health check failed: $e',
        'error_code': 'HEALTH_CHECK_ERROR'
      };
    }
  }

  /// サポートされている音声フォーマット取得
  /// 
  /// Returns: フォーマット情報
  static Future<Map<String, dynamic>> getSupportedFormats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/ai/formats'),
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to get formats: $e',
        'error_code': 'FORMATS_ERROR'
      };
    }
  }
}