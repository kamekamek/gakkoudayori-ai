import 'dart:convert';

/// Delta ↔ HTML 変換サービス
/// Quill.jsのDelta形式とHTMLの相互変換を提供
class DeltaConverter {
  /// Delta JSON を HTML に変換
  String deltaToHtml(String deltaJson) {
    try {
      final delta = parseDelta(deltaJson);
      return _convertDeltaToHtml(delta);
    } catch (e) {
      throw FormatException('Failed to convert Delta to HTML: $e');
    }
  }

  /// HTML を Delta JSON に変換
  String htmlToDelta(String html) {
    try {
      final delta = _convertHtmlToDelta(html);
      return jsonEncode(delta.toJson());
    } catch (e) {
      throw FormatException('Failed to convert HTML to Delta: $e');
    }
  }

  /// Delta JSON をパース
  QuillDelta parseDelta(String deltaJson) {
    if (deltaJson.isEmpty) return QuillDelta(ops: []);
    
    final json = jsonDecode(deltaJson) as Map<String, dynamic>;
    return QuillDelta.fromJson(json);
  }

  /// Delta から プレーンテキストを抽出
  String deltaToPlainText(String deltaJson) {
    final delta = parseDelta(deltaJson);
    return delta.ops
        .where((op) => op.insert is String)
        .map((op) => op.insert.toString())
        .join('')
        .replaceAll('\n', ' ')
        .trim();
  }

  /// Delta JSON の妥当性を検証
  bool isValidDelta(String deltaJson) {
    try {
      final json = jsonDecode(deltaJson) as Map<String, dynamic>;
      return json.containsKey('ops') && json['ops'] is List;
    } catch (e) {
      return false;
    }
  }

  /// Delta を HTML に変換（内部実装）
  String _convertDeltaToHtml(QuillDelta delta) {
    if (delta.ops.isEmpty) return '';

    final buffer = StringBuffer();
    final lines = <String>[];
    String currentLine = '';
    Map<String, dynamic>? lineAttributes;

    // Delta operations を行ごとに処理
    for (final op in delta.ops) {
      if (op.insert == '\n') {
        // 改行 - 現在の行を完了
        lines.add(_wrapLine(currentLine, lineAttributes));
        currentLine = '';
        lineAttributes = op.attributes;
      } else if (op.insert is String) {
        // テキスト追加
        final text = op.insert as String;
        final formattedText = _applyInlineFormatting(text, op.attributes);
        currentLine += formattedText;
      }
    }

    // 最後の行を追加（改行で終わらない場合）
    if (currentLine.isNotEmpty) {
      lines.add(_wrapLine(currentLine, lineAttributes));
    }

    // リストの処理
    return _processListItems(lines);
  }

  /// 行をHTML要素でラップ
  String _wrapLine(String content, Map<String, dynamic>? attributes) {
    if (content.isEmpty && attributes == null) return '';
    
    if (attributes?['list'] != null) {
      // リスト項目の場合は<li>タグでラップ
      return '<li data-list="${attributes!['list']}">$content</li>';
    }
    
    final tag = _getBlockTag(attributes);
    return '<$tag>$content</$tag>';
  }

  /// リスト項目をまとめてリストとして処理
  String _processListItems(List<String> lines) {
    final buffer = StringBuffer();
    String? currentListType;
    bool inList = false;

    for (final line in lines) {
      if (line.contains('data-list=')) {
        // リスト項目
        final listType = RegExp(r'data-list="([^"]*)"').firstMatch(line)?.group(1);
        
        if (!inList || currentListType != listType) {
          if (inList) {
            buffer.write(_getListCloseTag(currentListType!));
          }
          buffer.write(_getListOpenTag(listType!));
          inList = true;
          currentListType = listType;
        }
        
        // data-list属性を除去
        final cleanLine = line.replaceAll(RegExp(r' data-list="[^"]*"'), '');
        buffer.write(cleanLine);
      } else {
        // 通常の行
        if (inList) {
          buffer.write(_getListCloseTag(currentListType!));
          inList = false;
          currentListType = null;
        }
        buffer.write(line);
      }
    }

    if (inList) {
      buffer.write(_getListCloseTag(currentListType!));
    }

    return buffer.toString();
  }

  /// HTML を Delta に変換（内部実装）
  QuillDelta _convertHtmlToDelta(String html) {
    if (html.isEmpty) return QuillDelta(ops: []);

    final ops = <DeltaOperation>[];
    final cleanHtml = _sanitizeHtml(html);
    
    // 簡易的なHTML解析
    final elements = _parseHtmlElements(cleanHtml);
    
    for (final element in elements) {
      if (element.text.isNotEmpty) {
        // テキスト部分を追加
        ops.add(DeltaOperation(
          insert: element.text,
          attributes: element.attributes.isNotEmpty ? element.attributes : null,
        ));
        
        // ブロック要素の場合は改行を追加
        if (element.isBlock) {
          ops.add(DeltaOperation(
            insert: '\n',
            attributes: element.blockAttributes.isNotEmpty ? element.blockAttributes : null,
          ));
        }
      }
    }

    return QuillDelta(ops: ops);
  }

  /// HTMLエレメントを解析
  List<HtmlElement> _parseHtmlElements(String html) {
    final elements = <HtmlElement>[];
    
    // 基本的なパターンマッチング解析
    final patterns = [
      RegExp(r'<h([1-6])>(.*?)</h[1-6]>', caseSensitive: false),
      RegExp(r'<p>(.*?)</p>', caseSensitive: false),
      RegExp(r'<li>(.*?)</li>', caseSensitive: false),
      RegExp(r'<strong>(.*?)</strong>', caseSensitive: false),
      RegExp(r'<em>(.*?)</em>', caseSensitive: false),
    ];
    
    String remaining = html;
    
    // ヘッダー
    final headerMatches = RegExp(r'<h([1-6])>(.*?)</h[1-6]>', caseSensitive: false).allMatches(html);
    for (final match in headerMatches) {
      final level = int.parse(match.group(1)!);
      final text = _extractTextFromHtml(match.group(2)!);
      elements.add(HtmlElement(
        text: text,
        isBlock: true,
        blockAttributes: {'header': level},
      ));
    }
    
    // パラグラフ
    final pMatches = RegExp(r'<p>(.*?)</p>', caseSensitive: false).allMatches(html);
    for (final match in pMatches) {
      final text = _extractTextFromHtml(match.group(1)!);
      if (text.isNotEmpty) {
        elements.add(HtmlElement(
          text: text,
          isBlock: true,
        ));
      }
    }
    
    // フォールバック: プレーンテキスト
    if (elements.isEmpty) {
      final text = _extractTextFromHtml(html);
      if (text.isNotEmpty) {
        elements.add(HtmlElement(text: text, isBlock: false));
      }
    }

    return elements;
  }

  /// ブロック要素のタグを決定
  String _getBlockTag(Map<String, dynamic>? attributes) {
    if (attributes == null) return 'p';
    
    if (attributes.containsKey('header')) {
      return 'h${attributes['header']}';
    }
    if (attributes.containsKey('blockquote')) {
      return 'blockquote';
    }
    if (attributes.containsKey('code-block')) {
      return 'pre';
    }
    
    return 'p';
  }

  /// リスト開始タグを取得
  String _getListOpenTag(String listType) {
    switch (listType) {
      case 'bullet':
        return '<ul>';
      case 'ordered':
        return '<ol>';
      default:
        return '<ul>';
    }
  }

  /// リスト終了タグを取得
  String _getListCloseTag(String listType) {
    switch (listType) {
      case 'bullet':
        return '</ul>';
      case 'ordered':
        return '</ol>';
      default:
        return '</ul>';
    }
  }

  /// インライン書式を適用
  String _applyInlineFormatting(String text, Map<String, dynamic>? attributes) {
    if (attributes == null || attributes.isEmpty) {
      return _escapeHtml(text);
    }

    String formatted = _escapeHtml(text);
    
    if (attributes['bold'] == true) {
      formatted = '<strong>$formatted</strong>';
    }
    if (attributes['italic'] == true) {
      formatted = '<em>$formatted</em>';
    }
    if (attributes['underline'] == true) {
      formatted = '<u>$formatted</u>';
    }
    if (attributes['strike'] == true) {
      formatted = '<s>$formatted</s>';
    }
    if (attributes['code'] == true) {
      formatted = '<code>$formatted</code>';
    }
    
    // 色とサイズの処理
    if (attributes['color'] != null) {
      formatted = '<span style="color: ${attributes['color']}">$formatted</span>';
    }
    if (attributes['size'] != null) {
      formatted = '<span style="font-size: ${attributes['size']}">$formatted</span>';
    }

    return formatted;
  }

  /// HTMLエスケープ
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  /// HTMLサニタイズ（基本的なXSS対策）
  String _sanitizeHtml(String html) {
    // 危険なタグを除去
    final dangerousTags = ['script', 'object', 'embed', 'form', 'input'];
    String sanitized = html;
    
    for (final tag in dangerousTags) {
      sanitized = sanitized.replaceAll(RegExp('<$tag[^>]*>.*?</$tag>', caseSensitive: false), '');
      sanitized = sanitized.replaceAll(RegExp('<$tag[^>]*/?>', caseSensitive: false), '');
    }
    
    return sanitized;
  }

  /// HTMLからテキストを抽出（簡易実装）
  String _extractTextFromHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

/// Quill Delta データ構造
class QuillDelta {
  final List<DeltaOperation> ops;

  QuillDelta({required this.ops});

  factory QuillDelta.fromJson(Map<String, dynamic> json) {
    final opsList = json['ops'] as List? ?? [];
    final ops = opsList
        .map((op) => DeltaOperation.fromJson(op as Map<String, dynamic>))
        .toList();
    return QuillDelta(ops: ops);
  }

  Map<String, dynamic> toJson() {
    return {
      'ops': ops.map((op) => op.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'QuillDelta(ops: $ops)';
  }
}

/// Delta Operation データ構造
class DeltaOperation {
  final dynamic insert;
  final Map<String, dynamic>? attributes;
  final int? retain;
  final int? delete;

  DeltaOperation({
    this.insert,
    this.attributes,
    this.retain,
    this.delete,
  });

  factory DeltaOperation.fromJson(Map<String, dynamic> json) {
    return DeltaOperation(
      insert: json['insert'],
      attributes: json['attributes'] as Map<String, dynamic>?,
      retain: json['retain'] as int?,
      delete: json['delete'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (insert != null) json['insert'] = insert;
    if (attributes != null) json['attributes'] = attributes;
    if (retain != null) json['retain'] = retain;
    if (delete != null) json['delete'] = delete;
    return json;
  }

  @override
  String toString() {
    return 'DeltaOperation(insert: $insert, attributes: $attributes, retain: $retain, delete: $delete)';
  }
}

/// HTML要素の表現
class HtmlElement {
  final String text;
  final bool isBlock;
  final Map<String, dynamic> attributes;
  final Map<String, dynamic> blockAttributes;

  HtmlElement({
    required this.text,
    this.isBlock = false,
    this.attributes = const {},
    this.blockAttributes = const {},
  });

  @override
  String toString() {
    return 'HtmlElement(text: $text, isBlock: $isBlock, attributes: $attributes, blockAttributes: $blockAttributes)';
  }
}

/// Delta変換エラー
class DeltaConversionException implements Exception {
  final String message;
  final String? originalData;

  const DeltaConversionException(this.message, {this.originalData});

  @override
  String toString() {
    return 'DeltaConversionException: $message${originalData != null ? ' (Data: $originalData)' : ''}';
  }
}