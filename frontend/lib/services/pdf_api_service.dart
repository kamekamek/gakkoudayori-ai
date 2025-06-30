import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// PDF生成APIクライアント
///
/// バックエンドのPDF生成エンドポイントと通信
class PdfApiService {
  static final String _baseUrl = AppConfig.apiBaseUrl;

  /// HTMLからPDFを生成
  ///
  /// [htmlContent] PDF化するHTMLコンテンツ
  /// [title] ドキュメントタイトル
  /// [pageSize] ページサイズ（A4, A3等）
  /// [includeHeader] ヘッダーを含めるか
  /// [includeFooter] フッターを含めるか
  ///
  /// Returns: PDF生成結果（Base64エンコードされたPDFを含む）
  static Future<Map<String, dynamic>> generatePdf({
    required String htmlContent,
    String title = '学級通信',
    String pageSize = 'A4',
    String margin = '15mm',
    bool includeHeader = false,
    bool includeFooter = false,
    String customCss = '',
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/pdf/generate');

    final requestBody = {
      'html_content': htmlContent,
      'title': title,
      'page_size': pageSize,
      'margin': margin,
      'include_header': includeHeader,
      'include_footer': includeFooter,
      'custom_css': customCss,
    };

    try {
      if (kDebugMode) {
        print('PDF生成リクエスト送信: $url');
        print('タイトル: $title');
        print('HTMLコンテンツ長: ${htmlContent.length}文字');
      }

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 30), // 30秒タイムアウト
        onTimeout: () {
          throw Exception('PDF生成がタイムアウトしました（30秒）');
        },
      );

      if (kDebugMode) {
        print('PDF生成レスポンスステータス: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          if (kDebugMode) {
            final pdfData = responseData['data'];
            print(
                'PDF生成成功: ${pdfData['file_size_mb']} MB, ${pdfData['page_count']}ページ');
          }
          return responseData;
        } else {
          throw Exception(responseData['error'] ?? 'PDF生成でエラーが発生しました');
        }
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(
            'リクエストエラー: ${errorData['detail'] ?? 'Invalid request'}');
      } else if (response.statusCode == 500) {
        final errorData = jsonDecode(response.body);
        throw Exception(
            'サーバーエラー: ${errorData['detail'] ?? 'Internal server error'}');
      } else {
        throw Exception('PDF生成に失敗しました (HTTP ${response.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PDF生成エラー: $e');
      }

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw Exception('ネットワーク接続エラー: バックエンドサーバーに接続できません');
      } else if (e.toString().contains('TimeoutException') ||
          e.toString().contains('タイムアウト')) {
        throw Exception('PDF生成がタイムアウトしました。時間をおいて再試行してください');
      } else {
        rethrow;
      }
    }
  }

  /// PDF生成のテスト
  ///
  /// サービスが正常に動作するかテスト
  static Future<bool> testPdfGeneration() async {
    try {
      const testHtml = '''
      <h1>テスト学級通信</h1>
      <p>PDF生成機能のテストです。</p>
      <h2>テスト項目</h2>
      <ul>
        <li>日本語フォント表示</li>
        <li>HTML構造の維持</li>
        <li>スタイリングの適用</li>
      </ul>
      ''';

      final result = await generatePdf(
        htmlContent: testHtml,
        title: 'テスト学級通信',
        includeHeader: false,
        includeFooter: false,
      );

      return result['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('PDF生成テストエラー: $e');
      }
      return false;
    }
  }

  /// サーバーの健康状態チェック
  ///
  /// バックエンドサーバーが稼働中かチェック
  static Future<bool> checkServerHealth() async {
    try {
      final url = Uri.parse('$_baseUrl/health');
      final response = await http.get(url).timeout(
            const Duration(seconds: 5),
          );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('サーバー健康状態チェックエラー: $e');
      }
      return false;
    }
  }

  /// PDF生成可能性チェック
  ///
  /// HTMLコンテンツがPDF生成に適しているかチェック
  static Map<String, dynamic> validateHtmlForPdf(String htmlContent) {
    final issues = <String>[];
    final warnings = <String>[];

    // 基本的な検証
    if (htmlContent.trim().isEmpty) {
      issues.add('HTMLコンテンツが空です');
    }

    if (htmlContent.length < 10) {
      warnings.add('HTMLコンテンツが短すぎる可能性があります');
    }

    if (htmlContent.length > 1000000) {
      // 1MB
      warnings.add('HTMLコンテンツが大きすぎる可能性があります');
    }

    // 基本的なHTML構造チェック
    if (!htmlContent.contains('<')) {
      issues.add('HTMLタグが見つかりません');
    }

    // 潜在的に問題となる要素のチェック
    if (htmlContent.contains('<script')) {
      warnings.add('スクリプトタグが含まれています（PDF生成時に無視されます）');
    }

    if (htmlContent.contains('<iframe')) {
      warnings.add('iframeタグが含まれています（PDF生成時に正しく表示されない可能性があります）');
    }

    // 大きな画像の警告
    final base64ImageRegex =
        RegExp(r'data:image/[^;]+;base64,[A-Za-z0-9+/=]{10000,}');
    if (base64ImageRegex.hasMatch(htmlContent)) {
      warnings.add('大きなBase64画像が含まれています（PDF生成に時間がかかる可能性があります）');
    }

    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
    };
  }

  Future<Uint8List> generatePdfFromHtml(String htmlContent) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/pdf/from_html'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'html_content': htmlContent}),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        // ... エラーハンドリング ...
        String errorMessage = 'PDF生成エラー: Status=${response.statusCode}';
        try {
          final decoded = utf8.decode(response.bodyBytes);
          final jsonError = jsonDecode(decoded);
          errorMessage += ', Detail=${jsonError['detail']}';
        } catch (_) {
          // エラー詳細が取得できない場合
          errorMessage +=
              ', Body=${utf8.decode(response.bodyBytes, allowMalformed: true)}';
        }
        if (kDebugMode) {
          debugPrint(errorMessage);
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PDF API接続エラー: $e');
      }
      rethrow;
    }
  }
}
