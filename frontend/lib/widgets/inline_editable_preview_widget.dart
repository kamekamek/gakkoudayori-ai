import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:js_interop';

/// インライン編集可能なHTMLプレビューウィジェット
/// プレビュー画面で直接テキストをクリックして編集できる
class InlineEditablePreviewWidget extends StatefulWidget {
  final String htmlContent;
  final double height;
  final Function(String html)? onContentChanged;

  const InlineEditablePreviewWidget({
    Key? key,
    required this.htmlContent,
    required this.height,
    this.onContentChanged,
  }) : super(key: key);

  @override
  State<InlineEditablePreviewWidget> createState() =>
      _InlineEditablePreviewWidgetState();
}

class _InlineEditablePreviewWidgetState
    extends State<InlineEditablePreviewWidget> {
  String? _viewId;
  web.HTMLIFrameElement? _iframe;
  String _cachedContent = '';
  bool _isLoading = false;
  bool _isEditMode = false;

  // メッセージハンドラ
  html.EventListener? _messageHandler;

  @override
  void initState() {
    super.initState();
    _initializeEditableView();
    _setupMessageListener();
  }

  @override
  void dispose() {
    // メッセージリスナーをクリーンアップ
    if (_messageHandler != null) {
      html.window.removeEventListener('message', _messageHandler!);
    }
    super.dispose();
  }

  /// メッセージ通信をセットアップ
  void _setupMessageListener() {
    if (kDebugMode) debugPrint('🔧 [InlineEdit] メッセージリスナー設定開始');

    // 方法1: 標準のpostMessage
    _messageHandler = (html.Event event) {
      final messageEvent = event as html.MessageEvent;

      try {
        final data = messageEvent.data;
        if (kDebugMode)
          debugPrint(
              '🔍 [InlineEdit] postMessage受信 - データ型: ${data.runtimeType}');
        if (kDebugMode)
          debugPrint('🔍 [InlineEdit] postMessage受信 - データ内容: $data');

        Map<String, dynamic>? message;

        if (data is String) {
          if (kDebugMode) debugPrint('🔍 [InlineEdit] 文字列データをJSON解析中...');
          message = jsonDecode(data) as Map<String, dynamic>;
        } else if (data is Map) {
          if (kDebugMode) debugPrint('🔍 [InlineEdit] マップデータを直接使用...');
          message = Map<String, dynamic>.from(data);
        } else {
          if (kDebugMode)
            debugPrint('❌ [InlineEdit] 未対応のデータ型: ${data.runtimeType}');
          return;
        }

        if (message != null) {
          if (kDebugMode) debugPrint('🔍 [InlineEdit] 解析済みメッセージ: $message');
          _handleMessage(message);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('❌ [InlineEdit] メッセージ解析エラー: $e');
        if (kDebugMode) debugPrint('❌ [InlineEdit] 元データ: ${messageEvent.data}');
      }
    };

    html.window.addEventListener('message', _messageHandler!);
    if (kDebugMode) debugPrint('✅ [InlineEdit] postMessage リスナー設定完了');

    // 方法2: カスタムイベント
    final customEventHandler = (html.Event event) {
      try {
        final customEvent = event as html.CustomEvent;
        final data = customEvent.detail;
        if (kDebugMode)
          debugPrint('🔍 [InlineEdit] CustomEvent受信 - データ: $data');

        if (data is Map) {
          final message = Map<String, dynamic>.from(data);
          if (kDebugMode)
            debugPrint('🔍 [InlineEdit] CustomEvent解析済み: $message');
          _handleMessage(message);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('❌ [InlineEdit] CustomEvent解析エラー: $e');
      }
    };

    html.window.addEventListener('flutter-message', customEventHandler);
    if (kDebugMode) debugPrint('✅ [InlineEdit] CustomEvent リスナー設定完了');

    if (kDebugMode) debugPrint('🎯 [InlineEdit] 全てのメッセージリスナー設定完了');
  }

  /// iframe内からのメッセージを処理
  void _handleMessage(Map<String, dynamic> message) {
    if (kDebugMode) debugPrint('🔍 [InlineEdit] メッセージ処理開始: ${message['type']}');

    switch (message['type']) {
      case 'content_changed':
        if (kDebugMode) debugPrint('🔍 [InlineEdit] content_changed メッセージ受信');
        final data = message['data'];
        if (kDebugMode) debugPrint('🔍 [InlineEdit] data部分: $data');
        final newContent = data?['html'] as String?;
        if (kDebugMode)
          debugPrint('🔍 [InlineEdit] 抽出されたHTML: ${newContent?.length ?? 0}文字');

        if (newContent != null && widget.onContentChanged != null) {
          // HTMLコンテンツをクリーンアップしてから通知
          final cleanedContent = _cleanEditedContent(newContent);
          if (kDebugMode)
            debugPrint(
                '🔔 [InlineEdit] 編集内容を親ウィジェットに通知: ${cleanedContent.length}文字');
          if (kDebugMode)
            debugPrint(
                '🔔 [InlineEdit] クリーンアップ後の内容プレビュー: ${cleanedContent.substring(0, cleanedContent.length > 100 ? 100 : cleanedContent.length)}...');
          widget.onContentChanged!(cleanedContent);
        } else {
          if (kDebugMode)
            debugPrint(
                '❌ [InlineEdit] newContentがnullまたはonContentChangedがnull');
          if (kDebugMode) debugPrint('❌ [InlineEdit] newContent: $newContent');
          if (kDebugMode)
            debugPrint(
                '❌ [InlineEdit] onContentChanged: ${widget.onContentChanged}');
        }
        break;

      case 'edit_mode_changed':
        final isEditing = message['data']?['editing'] as bool? ?? false;
        if (mounted) {
          setState(() {
            _isEditMode = isEditing;
          });
        }
        break;

      default:
        if (kDebugMode)
          debugPrint('🔍 [InlineEdit] 未知のメッセージタイプ: ${message['type']}');
    }
  }

  void _initializeEditableView() {
    setState(() {
      _isLoading = true;
    });

    _viewId =
        'inline-editable-preview-${DateTime.now().millisecondsSinceEpoch}';
    _cachedContent = widget.htmlContent;

    // HTMLエレメントを作成
    final safeHeight = widget.height.isFinite ? widget.height : 500.0;
    _iframe = web.HTMLIFrameElement()
      ..width = '100%'
      ..height = '${safeHeight.toInt()}px'
      ..style.width = '100%'
      ..style.height = '${safeHeight}px'
      ..style.border = 'none'
      ..style.borderRadius = '8px';

    // インライン編集可能なHTMLコンテンツを作成
    final fullHtml = _createEditableHtml();
    final encodedHtml = Uri.dataFromString(
      fullHtml,
      mimeType: 'text/html',
      encoding: Encoding.getByName('utf-8')!,
    ).toString();

    _iframe!.src = encodedHtml;

    // iframe読み込み完了イベント
    _iframe!.onLoad.listen((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    // プラットフォームビューとして登録
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId!,
      (int viewId) => _iframe!,
    );
  }

  /// インライン編集可能なHTMLを作成
  String _createEditableHtml() {
    final content = _extractHtmlContent(widget.htmlContent);

    return '''
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>学級通信 - インライン編集</title>
    <style>
        html, body {
            margin: 0;
            padding: 0;
            font-family: 'Hiragino Sans', 'Yu Gothic', sans-serif; 
            line-height: 1.8;
            background-color: #fafafa;
            height: 100%;
            overflow-y: auto;
            -webkit-overflow-scrolling: touch;
        }
        
        body { 
            padding: 10px;
            position: relative;
        }
        
        @media (max-width: 768px) {
            body {
                padding: 8px;
            }
            .content {
                padding: 15px !important;
                margin: 0 !important;
            }
        }
        
        .edit-mode-indicator {
            position: fixed;
            top: 10px;
            right: 10px;
            background: #3498db;
            color: white;
            padding: 5px 10px;
            border-radius: 15px;
            font-size: 12px;
            display: none;
            z-index: 1000;
        }
        
        .content { 
            background: white; 
            padding: 20px; 
            border-radius: 8px; 
            box-shadow: 0 2px 8px rgba(0,0,0,0.1); 
            position: relative;
            margin-bottom: 20px;
            min-height: auto;
            box-sizing: border-box;
        }
        
        /* 長いコンテンツ用のスクロール改善 */
        .newsletter-container {
            width: 100% !important;
            max-width: none !important;
            margin: 0 !important;
        }
        
        /* モバイル対応のスクロール改善 */
        * {
            box-sizing: border-box;
        }
        
        /* 編集可能要素のスタイル */
        .editable {
            position: relative;
            transition: all 0.2s ease;
            border-radius: 4px;
            margin: 5px 0;
        }
        
        .editable:hover {
            background-color: #f8f9fa;
            outline: 2px dashed #3498db;
            cursor: pointer;
        }
        
        .editable.editing {
            background-color: #fff;
            outline: 2px solid #3498db;
            padding: 8px;
        }
        
        .editable:hover::after {
            content: "クリックして編集";
            position: absolute;
            top: -25px;
            left: 0;
            background: #3498db;
            color: white;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 11px;
            white-space: nowrap;
            z-index: 10;
        }
        
        .editable.editing::after {
            content: "Enter: 保存 / Esc: キャンセル";
            top: -25px;
            background: #27ae60;
        }
        
        /* 編集中の入力フィールド */
        .edit-input {
            border: none;
            outline: none;
            width: 100%;
            background: transparent;
            font: inherit;
            color: inherit;
            resize: vertical;
            min-height: 1.2em;
        }
        
        .edit-textarea {
            min-height: 60px;
            font-family: inherit;
            line-height: inherit;
        }
        
        /* 各要素のスタイル */
        h1.editable { 
            color: #2c3e50; 
            border-bottom: 3px solid #3498db; 
            padding-bottom: 10px; 
            margin-bottom: 20px; 
        }
        
        h2.editable { 
            color: #34495e; 
            margin-top: 30px; 
            margin-bottom: 15px; 
        }
        
        h3.editable { 
            color: #7f8c8d; 
            margin-top: 25px; 
            margin-bottom: 12px; 
        }
        
        p.editable { 
            margin-bottom: 15px; 
            color: #2c3e50; 
        }
        
        li.editable { 
            margin-bottom: 8px; 
            color: #34495e; 
        }
        
        .toolbar {
            position: absolute;
            top: -40px;
            left: 0;
            background: white;
            border: 1px solid #ddd;
            border-radius: 4px;
            padding: 5px;
            display: none;
            z-index: 100;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        
        .toolbar.show {
            display: flex;
            gap: 5px;
        }
        
        .toolbar button {
            background: #f8f9fa;
            border: 1px solid #ddd;
            border-radius: 3px;
            padding: 3px 8px;
            font-size: 11px;
            cursor: pointer;
        }
        
        .toolbar button:hover {
            background: #e9ecef;
        }
        
        .toolbar button.active {
            background: #3498db;
            color: white;
        }
    </style>
</head>
<body>
    <div class="edit-mode-indicator" id="editIndicator">編集モード</div>
    
    <div class="content" id="main-content">
        ${_makeContentEditable(content)}
    </div>
    
    <script>
        let isEditing = false;
        let currentEditElement = null;
        let originalContent = '';
        
        // 初期化
        document.addEventListener('DOMContentLoaded', function() {
            setupEditableElements();
        });
        
        function setupEditableElements() {
            const editables = document.querySelectorAll('.editable');
            
            editables.forEach(element => {
                element.addEventListener('click', function(e) {
                    e.stopPropagation();
                    if (!isEditing) {
                        startEdit(element);
                    }
                });
                
                element.addEventListener('keydown', function(e) {
                    if (element.classList.contains('editing')) {
                        if (e.key === 'Enter' && !e.shiftKey) {
                            e.preventDefault();
                            finishEdit(element, true);
                        } else if (e.key === 'Escape') {
                            e.preventDefault();
                            finishEdit(element, false);
                        }
                    }
                });
                
                element.addEventListener('blur', function() {
                    if (element.classList.contains('editing')) {
                        setTimeout(() => {
                            if (document.activeElement !== element) {
                                finishEdit(element, true);
                            }
                        }, 100);
                    }
                });
            });
            
            // 編集モード外をクリックで編集終了
            document.addEventListener('click', function(e) {
                if (isEditing && !e.target.closest('.editable')) {
                    finishEdit(currentEditElement, true);
                }
            });
        }
        
        function startEdit(element) {
            if (isEditing) return;
            
            isEditing = true;
            currentEditElement = element;
            originalContent = element.innerHTML;
            
            element.classList.add('editing');
            element.contentEditable = true;
            element.focus();
            
            // 編集モード表示
            document.getElementById('editIndicator').style.display = 'block';
            
            // Flutter側に編集開始を通知
            notifyFlutter('edit_mode_changed', { editing: true });
            
            // カーソルを最後に移動
            const range = document.createRange();
            const selection = window.getSelection();
            range.selectNodeContents(element);
            range.collapse(false);
            selection.removeAllRanges();
            selection.addRange(range);
        }
        
        function finishEdit(element, save) {
            if (!isEditing || !element) return;
            
            if (save) {
                const newContent = element.innerHTML;
                if (newContent !== originalContent) {
                    // 変更をFlutter側に通知
                    setTimeout(() => {
                        notifyContentChange();
                    }, 100); // 短い遅延でDOMの確実な更新を待つ
                }
            } else {
                // キャンセル: 元の内容に戻す
                element.innerHTML = originalContent;
            }
            
            element.classList.remove('editing');
            element.contentEditable = false;
            
            isEditing = false;
            currentEditElement = null;
            originalContent = '';
            
            // 編集モード非表示
            document.getElementById('editIndicator').style.display = 'none';
            
            // Flutter側に編集終了を通知
            notifyFlutter('edit_mode_changed', { editing: false });
        }
        
        function notifyContentChange() {
            // 完全なHTMLコンテンツを取得
            const fullContent = document.getElementById('main-content').outerHTML;
            console.log('📝 [InlineEdit] 内容変更通知:', fullContent.length + '文字');
            notifyFlutter('content_changed', { html: fullContent });
        }
        
        function notifyFlutter(type, data) {
            const message = {
                type: type,
                data: data
            };
            
            console.log('🚀 [InlineEdit] メッセージ送信開始:', message);
            
            // 方法1: window.parent
            try {
                if (window.parent && window.parent.postMessage) {
                    window.parent.postMessage(message, '*');
                    console.log('✅ [InlineEdit] window.parent.postMessage 送信完了');
                }
            } catch (e) {
                console.error('❌ [InlineEdit] window.parent.postMessage エラー:', e);
            }
            
            // 方法2: window.top
            try {
                if (window.top && window.top.postMessage && window.top !== window) {
                    window.top.postMessage(message, '*');
                    console.log('✅ [InlineEdit] window.top.postMessage 送信完了');
                }
            } catch (e) {
                console.error('❌ [InlineEdit] window.top.postMessage エラー:', e);
            }
            
            // 方法3: カスタムイベント（Flutter Web用）
            try {
                const customEvent = new CustomEvent('flutter-message', {
                    detail: message
                });
                window.dispatchEvent(customEvent);
                if (window.parent && window.parent !== window) {
                    window.parent.dispatchEvent(customEvent);
                }
                console.log('✅ [InlineEdit] CustomEvent 送信完了');
            } catch (e) {
                console.error('❌ [InlineEdit] CustomEvent エラー:', e);
            }
            
            console.log('🏁 [InlineEdit] 全ての送信方法を試行完了');
        }
        
        // 外部からのメッセージ受信
        window.addEventListener('message', function(event) {
            try {
                const message = typeof event.data === 'string' ? JSON.parse(event.data) : event.data;
                
                switch (message.type) {
                    case 'update_content':
                        if (message.data && message.data.html) {
                            const newContent = makeContentEditable(message.data.html);
                            document.getElementById('main-content').innerHTML = newContent;
                            setupEditableElements();
                        }
                        break;
                }
            } catch (e) {
                console.error('メッセージ処理エラー:', e);
            }
        });
        
        function makeContentEditable(html) {
            // HTMLの各要素を編集可能にマーク
            return html
                .replace(/<h1([^>]*)>/g, '<h1\$1 class="editable">')
                .replace(/<h2([^>]*)>/g, '<h2\$1 class="editable">')
                .replace(/<h3([^>]*)>/g, '<h3\$1 class="editable">')
                .replace(/<p([^>]*)>/g, '<p\$1 class="editable">')
                .replace(/<li([^>]*)>/g, '<li\$1 class="editable">');
        }
    </script>
</body>
</html>''';
  }

  /// HTMLコンテンツを編集可能な形式に変換
  String _makeContentEditable(String content) {
    return content
        .replaceAll('<h1', '<h1 class="editable"')
        .replaceAll('<h2', '<h2 class="editable"')
        .replaceAll('<h3', '<h3 class="editable"')
        .replaceAll('<p', '<p class="editable"')
        .replaceAll('<li', '<li class="editable"');
  }

  /// HTMLコンテンツから実際のコンテンツ部分を抽出
  String _extractHtmlContent(String htmlContent) {
    String cleaned =
        htmlContent.replaceAll('```html', '').replaceAll('```', '').trim();

    return cleaned.isEmpty ? '<p class="editable">コンテンツがありません</p>' : cleaned;
  }

  /// 編集されたHTMLコンテンツをクリーンアップ
  String _cleanEditedContent(String editedContent) {
    // outerHTMLから必要な部分だけを抽出
    String cleaned = editedContent;

    // <div class="content" id="main-content">...</div> の部分からinnerHTMLを取得
    final contentMatch = RegExp(r'<div[^>]*id="main-content"[^>]*>(.*?)</div>',
            multiLine: true, dotAll: true)
        .firstMatch(cleaned);

    if (contentMatch != null) {
      cleaned = contentMatch.group(1) ?? cleaned;
    }

    // editableクラスを除去（プレビュー用）
    cleaned = cleaned.replaceAll(' class="editable"', '');
    cleaned = cleaned.replaceAll('class="editable" ', '');
    cleaned = cleaned.replaceAll('class="editable"', '');

    return cleaned.trim();
  }

  /// 外部からコンテンツを更新
  void updateContent(String newContent) {
    if (_iframe?.contentWindow != null) {
      try {
        final message = jsonEncode({
          'type': 'update_content',
          'data': {
            'html': _makeContentEditable(_extractHtmlContent(newContent))
          }
        });

        _iframe!.contentWindow!
            .postMessage(js_util.jsify(jsonDecode(message)), '*'.toJS);
        _cachedContent = newContent;
      } catch (e) {
        if (kDebugMode) debugPrint('❌ [InlineEdit] コンテンツ更新エラー: $e');
      }
    }
  }

  @override
  void didUpdateWidget(InlineEditablePreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlContent != widget.htmlContent) {
      updateContent(widget.htmlContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeHeight = widget.height.isFinite ? widget.height : 500.0;

    if (_viewId == null) {
      return Container(
        height: safeHeight,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      height: safeHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isEditMode ? Colors.blue[300]! : Colors.grey[300]!,
          width: _isEditMode ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: HtmlElementView(
              viewType: _viewId!,
            ),
          ),

          // 編集モードインジケータ
          if (_isEditMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      '編集中',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ローディングインジケータ
          if (_isLoading)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'インライン編集プレビューを準備中...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
