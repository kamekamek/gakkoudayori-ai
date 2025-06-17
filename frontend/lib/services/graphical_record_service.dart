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
          jsonData: data['data'],
          warnings: (data['warnings'] as List<dynamic>?)?.cast<String>(),
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
            /* プレビューと完全一致のCSS - PrintPreviewWidgetと統一 */
            
            /* 基本リセット（最小限） */
            * {
                box-sizing: border-box;
            }
            
            /* A4サイズの固定レイアウト（210mm × 297mm） */
            html, body {
                font-family: 'Noto Sans JP', 'Hiragino Sans', 'Yu Gothic', sans-serif !important;
                margin: 0;
                padding: 0;
                background-color: white;
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }
            
            /* 印刷用コンテナ - A4固定サイズ */
            .print-container {
                width: 210mm;
                min-height: 297mm;
                max-width: 210mm;
                margin: 0 auto;
                padding: 15mm;
                background: white;
                position: relative;
            }
            
            /* 元のa4-sheetクラスがある場合の調整 */
            .a4-sheet {
                width: 100% !important;
                min-height: auto !important;
                margin: 0 !important;
                padding: 10mm !important;
                box-shadow: none !important;
            }
            
            /* フォントサイズとマージンの統一（プレビューと同じ） */
            h1 {
                font-size: 18px !important;
                margin: 8px 0 !important;
                line-height: 1.2 !important;
            }
            
            h2 {
                font-size: 16px !important;
                margin: 6px 0 !important;
                line-height: 1.2 !important;
            }
            
            h3 {
                font-size: 14px !important;
                margin: 4px 0 !important;
                line-height: 1.2 !important;
            }
            
            p {
                font-size: 12px !important;
                line-height: 1.3 !important;
                margin: 3px 0 !important;
            }
            
            /* セクション間隔の最適化 */
            .section {
                margin-bottom: 8px !important;
                padding: 8px !important;
            }
            
            .content-section {
                margin-bottom: 6px !important;
                padding: 6px !important;
            }
            
            /* ヘッダー・フッターの最適化 */
            .newsletter-header {
                margin-bottom: 10px !important;
                padding: 8px !important;
            }
            
            .footer-note {
                margin-top: 10px !important;
                padding: 6px !important;
            }
            
            /* 画像の最大幅制限 */
            img {
                max-width: 100% !important;
                height: auto !important;
            }
            
            /* テーブルの改ページ制御 */
            table {
                page-break-inside: avoid;
            }
            
            /* 改ページ制御 */
            .page-break {
                page-break-before: always;
            }
            
            .no-break {
                page-break-inside: avoid;
            }
            
            /* PDF出力時の追加調整 */
            @media print {
                .print-container {
                    width: 100% !important;
                    margin: 0 !important;
                    padding: 0 !important;
                    box-shadow: none !important;
                }
                
                .a4-sheet {
                    box-shadow: none !important;
                }
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
  final String? error;
  final String? errorCode;
  final List<String>? warnings;

  SpeechToJsonResult({
    required this.success,
    this.jsonData,
    this.error,
    this.errorCode,
    this.warnings,
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
