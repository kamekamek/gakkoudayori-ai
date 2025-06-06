import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../providers/auth_provider.dart';

class ApiService {
  static const String baseUrl = kDebugMode
      ? 'http://localhost:8000' // 開発環境
      : 'https://your-production-url.com'; // 本番環境

  final AuthProvider _authProvider;

  ApiService(this._authProvider);

  /// 認証ヘッダーを含むHTTPヘッダーを取得
  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Firebase IDトークンを取得
    final token = await _authProvider.getIdToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// HTTPリクエストのエラーハンドリング
  void _handleResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'API request failed: ${response.statusCode}',
        details: response.body,
      );
    }
  }

  /// GET リクエスト
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      _handleResponse(response);
      return json.decode(response.body);
    } catch (e) {
      debugPrint('GET $endpoint failed: $e');
      rethrow;
    }
  }

  /// POST リクエスト
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      _handleResponse(response);
      return json.decode(response.body);
    } catch (e) {
      debugPrint('POST $endpoint failed: $e');
      rethrow;
    }
  }

  /// PUT リクエスト
  Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      _handleResponse(response);
      return json.decode(response.body);
    } catch (e) {
      debugPrint('PUT $endpoint failed: $e');
      rethrow;
    }
  }

  /// DELETE リクエスト
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      _handleResponse(response);
      return json.decode(response.body);
    } catch (e) {
      debugPrint('DELETE $endpoint failed: $e');
      rethrow;
    }
  }

  // =============================================================================
  // AI関連のAPIエンドポイント
  // =============================================================================

  /// テキストを学級通信風に変換
  Future<Map<String, dynamic>> enhanceText({
    required String text,
    String style = 'friendly',
    String? customInstruction,
    String gradeLevel = 'elementary',
  }) async {
    return await post('/ai/enhance-text', {
      'text': text,
      'style': style,
      'custom_instruction': customInstruction,
      'grade_level': gradeLevel,
    });
  }

  /// コンテンツから見出しを自動生成
  Future<Map<String, dynamic>> generateHeadlines({
    required String content,
    int maxHeadlines = 5,
  }) async {
    return await post('/ai/generate-headlines', {
      'content': content,
      'max_headlines': maxHeadlines,
    });
  }

  /// レイアウトを自動生成
  Future<Map<String, dynamic>> generateLayout({
    required String content,
    String season = 'current',
    String? eventType,
  }) async {
    return await post('/ai/generate-layout', {
      'content': content,
      'season': season,
      'event_type': eventType,
    });
  }

  /// 音声をテキストに変換
  Future<Map<String, dynamic>> speechToText({
    required File audioFile,
  }) async {
    try {
      final headers = await _getHeaders();
      headers.remove('Content-Type'); // マルチパートの場合は自動設定される

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ai/speech-to-text'),
      );

      // ヘッダーを追加
      request.headers.addAll(headers);

      // 音声ファイルを追加
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio_file',
          audioFile.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _handleResponse(response);
      return json.decode(response.body);
    } catch (e) {
      debugPrint('Speech-to-text failed: $e');
      rethrow;
    }
  }

  /// 音声ファイルパスから音声認識（便利メソッド）
  Future<Map<String, dynamic>> transcribeAudio(String audioPath) async {
    final audioFile = File(audioPath);
    if (!await audioFile.exists()) {
      throw ApiException(
        statusCode: 400,
        message: 'Audio file not found',
        details: 'File path: $audioPath',
      );
    }
    return await speechToText(audioFile: audioFile);
  }

  // =============================================================================
  // ドキュメント管理API
  // =============================================================================

  /// ドキュメント一覧を取得
  Future<Map<String, dynamic>> getDocuments() async {
    return await get('/documents');
  }

  /// 新しいドキュメントを作成
  Future<Map<String, dynamic>> createDocument({
    required String title,
    String content = '',
  }) async {
    return await post('/documents', {
      'title': title,
      'content': content,
    });
  }

  /// ドキュメントを取得
  Future<Map<String, dynamic>> getDocument(String documentId) async {
    return await get('/documents/$documentId');
  }

  /// ドキュメントを更新
  Future<Map<String, dynamic>> updateDocument({
    required String documentId,
    String? title,
    String? content,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (content != null) data['content'] = content;

    return await put('/documents/$documentId', data);
  }

  /// ドキュメントを削除
  Future<Map<String, dynamic>> deleteDocument(String documentId) async {
    return await delete('/documents/$documentId');
  }

  // =============================================================================
  // テンプレート管理API
  // =============================================================================

  /// テンプレート一覧を取得
  Future<Map<String, dynamic>> getTemplates() async {
    return await get('/templates');
  }

  /// 特定のテンプレートを取得
  Future<Map<String, dynamic>> getTemplate(String templateId) async {
    return await get('/templates/$templateId');
  }

  // =============================================================================
  // PDF生成API
  // =============================================================================

  /// HTMLをPDFに変換
  Future<Map<String, dynamic>> exportToPdf({
    required String html,
    required String title,
  }) async {
    return await post('/export/pdf', {
      'html': html,
      'title': title,
    });
  }
}

/// API例外クラス
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String details;

  ApiException({
    required this.statusCode,
    required this.message,
    required this.details,
  });

  @override
  String toString() {
    return 'ApiException($statusCode): $message\nDetails: $details';
  }
}
