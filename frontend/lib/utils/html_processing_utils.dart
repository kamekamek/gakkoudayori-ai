import 'package:flutter/foundation.dart';

/// HTML処理の統一化ユーティリティクラス
/// プレビュー表示とPDF生成での一貫したHTML処理を提供
class HtmlProcessingUtils {
  
  /// HTMLコンテンツから実際のコンテンツ部分を抽出・サニタイズ
  /// 
  /// - マークダウンコードブロック（```html ```）を除去
  /// - 危険なタグの除去
  /// - 空コンテンツのハンドリング
  static String extractAndSanitizeHtml(String htmlContent) {
    if (htmlContent.trim().isEmpty) {
      return '<p>プレビューコンテンツがありません</p>';
    }

    // マークダウンコードブロックの除去
    String cleaned = htmlContent
        .replaceAll(RegExp(r'```html\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    // 空の場合は再チェック
    if (cleaned.isEmpty) {
      return '<p>プレビューコンテンツがありません</p>';
    }

    // 基本的なHTMLサニタイズ
    cleaned = _sanitizeHtml(cleaned);

    return cleaned;
  }

  /// 危険なHTMLタグを除去する基本的なサニタイズ
  static String _sanitizeHtml(String html) {
    // 危険なタグの除去
    final dangerousTags = [
      r'<script[^>]*>.*?</script>',
      r'<iframe[^>]*>.*?</iframe>',
      r'<object[^>]*>.*?</object>',
      r'<embed[^>]*>.*?</embed>',
      r'<link[^>]*>',
      r'<meta[^>]*>',
    ];

    String sanitized = html;
    for (final pattern in dangerousTags) {
      sanitized = sanitized.replaceAll(RegExp(pattern, caseSensitive: false, dotAll: true), '');
    }

    return sanitized;
  }

  /// PDF生成とプレビューで統一されたフルHTMLドキュメントを生成
  /// 
  /// Playwrightでの生成と同じスタイリングを適用
  static String generateFullHtmlDocument(String htmlContent, {
    String title = '学級通信',
    bool includePrintStyles = false,
  }) {
    final processedContent = extractAndSanitizeHtml(htmlContent);
    
    // Playwrightと同じベースCSS
    final baseStyles = _getBaseStyles();
    final printStyles = includePrintStyles ? _getPrintStyles() : '';
    
    return '''
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title</title>
    <style>
$baseStyles
$printStyles
    </style>
</head>
<body>
    $processedContent
</body>
</html>''';
  }

  /// Playwrightと統一されたベースCSSスタイル
  static String _getBaseStyles() {
    return '''
        @page {
            size: A4;
            margin: 15mm;
        }
        
        body {
            font-family: 'Hiragino Sans', 'Yu Gothic', 'Noto Sans JP', sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
            background-color: #fff;
            font-size: 14px;
        }
        
        h1 {
            font-size: 24px;
            font-weight: bold;
            color: #2c3e50;
            text-align: center;
            margin: 0 0 20px 0;
            padding-bottom: 15px;
            border-bottom: 3px solid #3498db;
        }
        
        h2 {
            font-size: 18px;
            font-weight: bold;
            color: #2c3e50;
            margin: 25px 0 15px 0;
            padding: 10px 15px;
            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
            border-left: 4px solid #3498db;
            border-radius: 4px;
        }
        
        h3 {
            font-size: 16px;
            font-weight: bold;
            color: #34495e;
            margin: 20px 0 10px 0;
        }
        
        p {
            margin: 10px 0;
            text-align: justify;
        }
        
        ul, ol {
            margin: 15px 0;
            padding-left: 25px;
        }
        
        li {
            margin: 8px 0;
            line-height: 1.5;
        }
        
        strong {
            font-weight: bold;
            color: #2c3e50;
        }
        
        em {
            font-style: italic;
            color: #7f8c8d;
        }
        
        .header {
            text-align: center;
            border-bottom: 2px solid #3498db;
            padding-bottom: 15px;
            margin-bottom: 25px;
        }
        
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 15px;
            border-top: 1px solid #bdc3c7;
            color: #7f8c8d;
            font-size: 12px;
        }
        
        .date-info {
            text-align: center;
            font-size: 14px;
            color: #7f8c8d;
            margin: 10px 0 20px 0;
        }
        
        .author-info {
            text-align: right;
            font-size: 14px;
            color: #7f8c8d;
            margin-top: 25px;
            font-style: italic;
        }
        
        /* テーブルスタイル */
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 15px 0;
        }
        
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        
        th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        
        /* 特殊な色指定への対応 */
        .highlight {
            background-color: #fff3cd;
            padding: 2px 4px;
            border-radius: 3px;
        }
        
        .important {
            color: #e74c3c;
            font-weight: bold;
        }
        
        /* スクロール対応（プレビュー用） */
        .newsletter-container {
            max-width: 210mm;
            margin: 0 auto;
            background: white;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
            border-radius: 8px;
            overflow: hidden;
        }
''';
  }

  /// 印刷専用CSSスタイル
  static String _getPrintStyles() {
    return '''
        @media print {
            body {
                padding: 0;
                margin: 0;
                font-size: 12pt;
                background: white !important;
                box-shadow: none !important;
            }
            
            .newsletter-container {
                box-shadow: none !important;
                border-radius: 0 !important;
                margin: 0 !important;
                padding: 0 !important;
            }
            
            h1 {
                font-size: 18pt;
                color: #000 !important;
            }
            
            h2 {
                font-size: 14pt;
                color: #000 !important;
                background: transparent !important;
                border-left: 2pt solid #000 !important;
            }
            
            h3 {
                font-size: 12pt;
                color: #000 !important;
            }
            
            .no-print {
                display: none !important;
            }
            
            .page-break {
                page-break-before: always;
            }
            
            a {
                color: #000 !important;
                text-decoration: none !important;
            }
            
            .highlight {
                background-color: #f0f0f0 !important;
            }
        }
''';
  }

  /// HTMLコンテンツのバリデーション
  static Map<String, dynamic> validateHtmlContent(String htmlContent) {
    final issues = <String>[];
    final warnings = <String>[];

    // 基本的な検証
    if (htmlContent.trim().isEmpty) {
      issues.add('HTMLコンテンツが空です');
      return {
        'isValid': false,
        'issues': issues,
        'warnings': warnings,
      };
    }

    final processed = extractAndSanitizeHtml(htmlContent);

    // 長さチェック
    if (processed.length < 10) {
      warnings.add('HTMLコンテンツが短すぎる可能性があります');
    }

    if (processed.length > 500000) { // 500KB
      warnings.add('HTMLコンテンツが大きすぎる可能性があります');
    }

    // 基本的なHTML構造チェック
    if (!processed.contains('<')) {
      issues.add('有効なHTMLタグが見つかりません');
    }

    // 潜在的問題の検出
    if (htmlContent.contains('<script')) {
      warnings.add('スクリプトタグが検出されました（除去されます）');
    }

    if (htmlContent.contains('<iframe')) {
      warnings.add('iframeタグが検出されました（除去されます）');
    }

    // 大きなBase64画像の警告
    final base64ImageRegex = RegExp(r'data:image/[^;]+;base64,[A-Za-z0-9+/=]{10000,}');
    if (base64ImageRegex.hasMatch(htmlContent)) {
      warnings.add('大きなBase64画像が含まれています（処理に時間がかかる可能性があります）');
    }

    if (kDebugMode) {
      debugPrint('📋 [HtmlUtils] HTMLバリデーション完了: ${issues.length}件の問題, ${warnings.length}件の警告');
    }

    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'processedContent': processed,
    };
  }

  /// HTMLコンテンツから要約を抽出（再生成機能用）
  static String extractContentSummary(String htmlContent) {
    final processed = extractAndSanitizeHtml(htmlContent);
    
    // タイトルの抽出
    final titleMatch = RegExp(r'<h1[^>]*>(.*?)</h1>', dotAll: true).firstMatch(processed);
    final title = titleMatch?.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '';

    // セクションの抽出
    final h2Matches = RegExp(r'<h2[^>]*>(.*?)</h2>', dotAll: true).allMatches(processed);
    final sections = h2Matches
        .map((match) => match.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '')
        .where((section) => section.isNotEmpty)
        .toList();

    // 本文の一部を抽出（最初の段落）
    final pMatch = RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true).firstMatch(processed);
    final firstParagraph = pMatch?.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '';

    var summary = '';
    if (title.isNotEmpty) {
      summary += 'タイトル: $title\n';
    }
    if (sections.isNotEmpty) {
      summary += 'セクション: ${sections.take(5).join(", ")}\n';
    }
    if (firstParagraph.isNotEmpty && firstParagraph.length > 10) {
      final preview = firstParagraph.length > 100 
          ? '${firstParagraph.substring(0, 100)}...' 
          : firstParagraph;
      summary += '内容プレビュー: $preview';
    }

    return summary.isEmpty ? 'HTMLコンテンツが検出されました' : summary;
  }

  /// HTMLコンテンツのテキスト長を取得
  static int getTextLength(String htmlContent) {
    final processed = extractAndSanitizeHtml(htmlContent);
    return processed.replaceAll(RegExp(r'<[^>]*>'), '').trim().length;
  }

  /// HTMLコンテンツにヘッダーが含まれているかチェック
  static bool hasHeader(String htmlContent) {
    final processed = extractAndSanitizeHtml(htmlContent);
    return RegExp(r'<h[1-6][^>]*>', caseSensitive: false).hasMatch(processed);
  }
}