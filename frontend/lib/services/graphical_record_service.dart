import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// グラフィックレコーディング（グラレコ）生成サービス
/// 新フロー: 音声→JSON→HTMLグラレコ
class GraphicalRecordService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  /// 音声認識結果をJSON構造化データに変換
  Future<SpeechToJsonResult> convertSpeechToJson({
    required String transcribedText,
    String customContext = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/speech-to-json'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'transcribed_text': transcribedText,
          'custom_context': customContext,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return SpeechToJsonResult(
          success: true,
          jsonData: data['data']['json_data'],
          sourceText: data['data']['source_text'],
          validationInfo: data['data']['validation_info'],
          processingTimeMs: data['data']['processing_time_ms'],
          timestamp: data['data']['timestamp'],
        );
      } else {
        return SpeechToJsonResult(
          success: false,
          error: data['error']['message'] ?? 'Unknown error',
          errorCode: data['error']['code'] ?? 'UNKNOWN_ERROR',
        );
      }
    } catch (e) {
      return SpeechToJsonResult(
        success: false,
        error: 'Network error: $e',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  /// JSON構造化データからHTMLグラレコを生成
  Future<JsonToGraphicalRecordResult> convertJsonToGraphicalRecord({
    required Map<String, dynamic> jsonData,
    String template = 'colorful',
    String customStyle = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/json-to-graphical-record'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'json_data': jsonData,
          'template': template,
          'custom_style': customStyle,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return JsonToGraphicalRecordResult(
          success: true,
          htmlContent: data['data']['html_content'],
          sourceJson: data['data']['source_json'],
          templateInfo: data['data']['template_info'],
          generationInfo: data['data']['generation_info'],
          processingTimeMs: data['data']['processing_time_ms'],
          timestamp: data['data']['timestamp'],
        );
      } else {
        return JsonToGraphicalRecordResult(
          success: false,
          error: data['error']['message'] ?? 'Unknown error',
          errorCode: data['error']['code'] ?? 'UNKNOWN_ERROR',
        );
      }
    } catch (e) {
      return JsonToGraphicalRecordResult(
        success: false,
        error: 'Network error: $e',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  /// 利用可能なテンプレート一覧を取得
  List<GraphicalRecordTemplate> getAvailableTemplates() {
    return [
      GraphicalRecordTemplate(
        id: 'colorful',
        name: 'カラフル',
        description: '明るい色彩で楽しい雰囲気',
        style: 'modern',
      ),
      GraphicalRecordTemplate(
        id: 'monochrome',
        name: 'モノクロ',
        description: 'シンプルで落ち着いた印象',
        style: 'classic',
      ),
      GraphicalRecordTemplate(
        id: 'pastel',
        name: 'パステル',
        description: '優しい色合いで温かい印象',
        style: 'soft',
      ),
    ];
  }

  /// HTMLコンテンツをPDFに変換
  Future<PdfConversionResult> convertHtmlToPdf(String htmlContent) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-pdf'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'html_content': htmlContent,
          'title': '学級通信',
          'page_size': 'A4',
          'margin': '15mm',
          'include_header': false,
          'include_footer': false,
          'custom_css': '''
            /* PDF出力時の追加調整 - 1ページ収納最適化 */
            @media print {
              .a4-sheet {
                box-shadow: none !important;
                margin: 0 !important;
                padding: 10mm !important;
              }
              
              .print-container {
                box-shadow: none !important;
                margin: 0 !important;
                padding: 0 !important;
              }
              
              /* フォントサイズとマージンの最適化 */
              h1 { font-size: 18px !important; margin: 8px 0 !important; }
              h2 { font-size: 16px !important; margin: 6px 0 !important; }
              h3 { font-size: 14px !important; margin: 4px 0 !important; }
              p { font-size: 12px !important; margin: 3px 0 !important; line-height: 1.3 !important; }
              
              /* セクション間隔の最適化 */
              .section { margin-bottom: 8px !important; padding: 8px !important; }
              .content-section { margin-bottom: 6px !important; padding: 6px !important; }
              
              /* ヘッダー・フッターの最適化 */
              .newsletter-header { margin-bottom: 10px !important; padding: 8px !important; }
              .footer-note { margin-top: 10px !important; padding: 6px !important; }
              
              /* 不要な改ページを防ぐ */
              * { page-break-inside: avoid !important; }
              h1, h2, h3 { page-break-after: avoid !important; }
            }
          ''',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final pdfBase64 = data['data']['pdf_base64'];
          return PdfConversionResult(
              success: true, pdfData: base64Decode(pdfBase64));
        } else {
          return PdfConversionResult(
              success: false, error: data['error'] ?? 'Backend error');
        }
      } else {
        return PdfConversionResult(
            success: false, error: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      return PdfConversionResult(success: false, error: 'Network error: $e');
    }
  }
}

class PdfConversionResult {
  final bool success;
  final List<int>? pdfData;
  final String? error;

  PdfConversionResult({required this.success, this.pdfData, this.error});
}

/// 音声→JSON変換結果
class SpeechToJsonResult {
  final bool success;
  final Map<String, dynamic>? jsonData;
  final String? sourceText;
  final Map<String, dynamic>? validationInfo;
  final int? processingTimeMs;
  final String? timestamp;
  final String? error;
  final String? errorCode;

  SpeechToJsonResult({
    required this.success,
    this.jsonData,
    this.sourceText,
    this.validationInfo,
    this.processingTimeMs,
    this.timestamp,
    this.error,
    this.errorCode,
  });
}

/// JSON→HTMLグラレコ変換結果
class JsonToGraphicalRecordResult {
  final bool success;
  final String? htmlContent;
  final Map<String, dynamic>? sourceJson;
  final Map<String, dynamic>? templateInfo;
  final Map<String, dynamic>? generationInfo;
  final int? processingTimeMs;
  final String? timestamp;
  final String? error;
  final String? errorCode;

  JsonToGraphicalRecordResult({
    required this.success,
    this.htmlContent,
    this.sourceJson,
    this.templateInfo,
    this.generationInfo,
    this.processingTimeMs,
    this.timestamp,
    this.error,
    this.errorCode,
  });
}

/// グラレコテンプレート情報
class GraphicalRecordTemplate {
  final String id;
  final String name;
  final String description;
  final String style;

  GraphicalRecordTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.style,
  });
}
