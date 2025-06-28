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

  /// HTML構造保持型エディター用の高度な処理機能
  
  /// HTML要素の構造を保持しながら安全にサニタイズ
  /// リッチエディター用に設計されており、スタイル属性やクラスを保持
  static String sanitizeForRichEditor(String htmlContent) {
    if (htmlContent.trim().isEmpty) {
      return '<p>ここに学級通信の内容を入力してください...</p>';
    }

    String sanitized = htmlContent;

    // 危険なタグの除去（セキュリティ重視）
    final dangerousTags = [
      r'<script[^>]*>.*?</script>',
      r'<iframe[^>]*>.*?</iframe>', 
      r'<object[^>]*>.*?</object>',
      r'<embed[^>]*>.*?</embed>',
      r'<link[^>]*>',
      r'<meta[^>]*>',
      r'<form[^>]*>.*?</form>',
      r'<input[^>]*>',
      r'<button[^>]*>.*?</button>',
    ];

    for (final pattern in dangerousTags) {
      sanitized = sanitized.replaceAll(
        RegExp(pattern, caseSensitive: false, dotAll: true), 
        ''
      );
    }

    // 危険なイベント属性の除去
    final dangerousAttributes = [
      r'on\w+="[^"]*"',
      r"on\w+='[^']*'",
      r'javascript:[^"' "'" r'>\s]*',
    ];

    for (final pattern in dangerousAttributes) {
      sanitized = sanitized.replaceAll(
        RegExp(pattern, caseSensitive: false), 
        ''
      );
    }

    // 空のHTMLタグを整理
    sanitized = _cleanEmptyTags(sanitized);

    return sanitized;
  }

  /// 空のHTMLタグを整理
  static String _cleanEmptyTags(String html) {
    // 空のタグパターン（中身が空白のみ、または完全に空）
    final emptyTagPatterns = [
      r'<p[^>]*>\s*</p>',
      r'<div[^>]*>\s*</div>',
      r'<span[^>]*>\s*</span>',
      r'<h[1-6][^>]*>\s*</h[1-6]>',
    ];

    String cleaned = html;
    for (final pattern in emptyTagPatterns) {
      cleaned = cleaned.replaceAll(RegExp(pattern, dotAll: true), '');
    }

    // 連続する改行を整理
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');

    return cleaned.trim();
  }

  /// HTML要素の構造分析
  /// エディター用にHTML要素の階層構造を分析
  static Map<String, dynamic> analyzeHtmlStructure(String htmlContent) {
    final processed = sanitizeForRichEditor(htmlContent);
    
    // 見出しの抽出
    final headings = <Map<String, String>>[];
    for (int level = 1; level <= 6; level++) {
      final headingRegex = RegExp(r'<h' + level.toString() + r'[^>]*>(.*?)</h' + level.toString() + r'>', dotAll: true);
      final matches = headingRegex.allMatches(processed);
      for (final match in matches) {
        headings.add({
          'level': level.toString(),
          'text': match.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '',
          'html': match.group(0) ?? '',
        });
      }
    }

    // 段落の抽出
    final paragraphs = <String>[];
    final paragraphRegex = RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true);
    final paragraphMatches = paragraphRegex.allMatches(processed);
    for (final match in paragraphMatches) {
      final text = match.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '';
      if (text.isNotEmpty) {
        paragraphs.add(text);
      }
    }

    // リストの抽出
    final lists = <Map<String, dynamic>>[];
    final ulRegex = RegExp(r'<ul[^>]*>(.*?)</ul>', dotAll: true);
    final olRegex = RegExp(r'<ol[^>]*>(.*?)</ol>', dotAll: true);
    
    // 順序なしリスト
    final ulMatches = ulRegex.allMatches(processed);
    for (final match in ulMatches) {
      final listHtml = match.group(1) ?? '';
      final items = _extractListItems(listHtml);
      if (items.isNotEmpty) {
        lists.add({
          'type': 'ul',
          'items': items,
        });
      }
    }

    // 順序付きリスト
    final olMatches = olRegex.allMatches(processed);
    for (final match in olMatches) {
      final listHtml = match.group(1) ?? '';
      final items = _extractListItems(listHtml);
      if (items.isNotEmpty) {
        lists.add({
          'type': 'ol',
          'items': items,
        });
      }
    }

    // スタイル情報の抽出
    final styles = _extractStyleInformation(processed);

    return {
      'headings': headings,
      'paragraphs': paragraphs,
      'lists': lists,
      'styles': styles,
      'wordCount': _countWords(processed),
      'characterCount': processed.length,
      'estimatedReadingTime': _estimateReadingTime(processed),
    };
  }

  /// リストアイテムの抽出
  static List<String> _extractListItems(String listHtml) {
    final items = <String>[];
    final itemRegex = RegExp(r'<li[^>]*>(.*?)</li>', dotAll: true);
    final matches = itemRegex.allMatches(listHtml);
    for (final match in matches) {
      final text = match.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '';
      if (text.isNotEmpty) {
        items.add(text);
      }
    }
    return items;
  }

  /// スタイル情報の抽出
  static Map<String, dynamic> _extractStyleInformation(String html) {
    final styleInfo = <String, dynamic>{
      'hasColors': false,
      'hasBackgroundColors': false,
      'hasBoldText': false,
      'hasItalicText': false,
      'colorCount': 0,
      'fontSizes': <String>[],
    };

    // 色の使用チェック
    if (html.contains('color:') || html.contains('color=')) {
      styleInfo['hasColors'] = true;
      final colorMatches = RegExp(r'color:\s*([^;"' "'" r'>]+)', caseSensitive: false).allMatches(html);
      styleInfo['colorCount'] = colorMatches.length;
    }

    // 背景色の使用チェック
    if (html.contains('background-color:') || html.contains('background:')) {
      styleInfo['hasBackgroundColors'] = true;
    }

    // 太字のチェック
    if (html.contains('<strong>') || html.contains('<b>') || html.contains('font-weight:')) {
      styleInfo['hasBoldText'] = true;
    }

    // 斜体のチェック
    if (html.contains('<em>') || html.contains('<i>') || html.contains('font-style:')) {
      styleInfo['hasItalicText'] = true;
    }

    // フォントサイズの抽出
    final fontSizeMatches = RegExp(r'font-size:\s*([^;"' "'" r'>]+)', caseSensitive: false).allMatches(html);
    for (final match in fontSizeMatches) {
      final size = match.group(1)?.trim() ?? '';
      if (size.isNotEmpty && !styleInfo['fontSizes'].contains(size)) {
        styleInfo['fontSizes'].add(size);
      }
    }

    return styleInfo;
  }

  /// 単語数のカウント（日本語対応）
  static int _countWords(String html) {
    final text = html.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
    
    // 日本語文字のカウント（ひらがな、カタカナ、漢字）
    final japaneseChars = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').allMatches(text).length;
    
    // 英数字の単語のカウント
    final englishWords = text.split(RegExp(r'[\s\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]+')).where((word) => word.isNotEmpty).length;
    
    return japaneseChars + englishWords;
  }

  /// 読み取り時間の推定（分）
  static int _estimateReadingTime(String html) {
    final wordCount = _countWords(html);
    // 日本語の平均読み取り速度：400-600文字/分
    const averageReadingSpeed = 500;
    return (wordCount / averageReadingSpeed).ceil().clamp(1, 60);
  }

  /// HTML差分検出
  /// 編集前後のHTMLを比較して変更箇所を特定
  static Map<String, dynamic> detectHtmlChanges(String oldHtml, String newHtml) {
    final oldProcessed = sanitizeForRichEditor(oldHtml);
    final newProcessed = sanitizeForRichEditor(newHtml);

    if (oldProcessed == newProcessed) {
      return {
        'hasChanges': false,
        'changeType': 'none',
        'details': 'コンテンツに変更はありません',
      };
    }

    final changes = <String, dynamic>{
      'hasChanges': true,
      'oldLength': oldProcessed.length,
      'newLength': newProcessed.length,
      'lengthDiff': newProcessed.length - oldProcessed.length,
    };

    // 変更タイプの判定
    if (newProcessed.length > oldProcessed.length) {
      changes['changeType'] = 'addition';
      changes['details'] = '${changes['lengthDiff']}文字が追加されました';
    } else if (newProcessed.length < oldProcessed.length) {
      changes['changeType'] = 'deletion';
      changes['details'] = '${-changes['lengthDiff']}文字が削除されました';
    } else {
      changes['changeType'] = 'modification';
      changes['details'] = 'コンテンツが変更されました';
    }

    // 構造的変更の検出
    final oldStructure = analyzeHtmlStructure(oldHtml);
    final newStructure = analyzeHtmlStructure(newHtml);

    final structuralChanges = <String>[];
    
    if (oldStructure['headings'].length != newStructure['headings'].length) {
      structuralChanges.add('見出しの数が変更されました');
    }
    
    if (oldStructure['paragraphs'].length != newStructure['paragraphs'].length) {
      structuralChanges.add('段落の数が変更されました');
    }
    
    if (oldStructure['lists'].length != newStructure['lists'].length) {
      structuralChanges.add('リストの数が変更されました');
    }

    changes['structuralChanges'] = structuralChanges;
    changes['hasStructuralChanges'] = structuralChanges.isNotEmpty;

    return changes;
  }

  /// HTMLの復元・マージ機能
  /// 編集中にエラーが発生した場合の復元用
  static String restoreHtmlStructure(String corruptedHtml, String referenceHtml) {
    try {
      final sanitized = sanitizeForRichEditor(corruptedHtml);
      
      // 基本的なHTMLバリデーション
      if (sanitized.trim().isEmpty || !sanitized.contains('<')) {
        return referenceHtml;
      }

      // 閉じタグの不足をチェック・修正
      final corrected = _fixUnclosedTags(sanitized);
      
      return corrected.isNotEmpty ? corrected : referenceHtml;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔧 [HtmlUtils] HTML復元エラー: $e');
      }
      return referenceHtml;
    }
  }

  /// 閉じタグの不足を修正
  static String _fixUnclosedTags(String html) {
    final tagStack = <String>[];
    final fixedTags = <String>[];
    
    // 簡易的なタグ修正（完全なパーサーではない）
    final tagRegex = RegExp(r'<(/?)(\w+)[^>]*>');
    final matches = tagRegex.allMatches(html);
    
    String result = html;
    
    // 自己終了タグ
    const selfClosingTags = {'br', 'hr', 'img', 'input', 'meta', 'link'};
    
    for (final match in matches) {
      final isClosing = match.group(1) == '/';
      final tagName = match.group(2)?.toLowerCase() ?? '';
      
      if (selfClosingTags.contains(tagName)) {
        continue;
      }
      
      if (isClosing) {
        if (tagStack.isNotEmpty && tagStack.last == tagName) {
          tagStack.removeLast();
        }
      } else {
        tagStack.add(tagName);
      }
    }
    
    // 未閉じタグを閉じる
    for (final tag in tagStack.reversed) {
      result += '</$tag>';
    }
    
    return result;
  }
}