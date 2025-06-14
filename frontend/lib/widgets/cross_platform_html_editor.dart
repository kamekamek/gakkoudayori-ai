import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/platform_service.dart';
import 'html_widget_preview.dart';

/// クロスプラットフォーム対応HTMLエディタ
/// Web: HtmlWidgetPreview使用
/// Mobile: InAppWebView使用
class CrossPlatformHtmlEditor extends StatefulWidget {
  final String htmlContent;
  final double height;
  final Function(String)? onContentChanged;
  final bool isEditable;

  const CrossPlatformHtmlEditor({
    super.key,
    required this.htmlContent,
    this.height = 500,
    this.onContentChanged,
    this.isEditable = false,
  });

  @override
  State<CrossPlatformHtmlEditor> createState() => _CrossPlatformHtmlEditorState();
}

class _CrossPlatformHtmlEditorState extends State<CrossPlatformHtmlEditor> {
  InAppWebViewController? _webViewController;
  String _currentHtml = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentHtml = widget.htmlContent;
  }

  @override
  void didUpdateWidget(CrossPlatformHtmlEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlContent != widget.htmlContent) {
      _currentHtml = widget.htmlContent;
      if (PlatformService.isMobile && _webViewController != null) {
        _loadHtmlInWebView();
      }
    }
  }

  /// WebViewにHTMLコンテンツを読み込み
  Future<void> _loadHtmlInWebView() async {
    if (_webViewController == null) return;

    final htmlWithEditor = _buildMobileEditorHtml(_currentHtml);
    await _webViewController!.loadData(data: htmlWithEditor);
  }

  /// Mobile向けエディタHTMLを構築
  String _buildMobileEditorHtml(String content) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HTML Editor</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Hiragino Sans', 'Yu Gothic', sans-serif;
            margin: 0;
            padding: 16px;
            background: white;
            line-height: 1.6;
        }
        .editor-container {
            min-height: 400px;
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 16px;
            background: white;
        }
        .toolbar {
            display: flex;
            gap: 8px;
            margin-bottom: 16px;
            padding: 8px;
            background: #f5f5f5;
            border-radius: 4px;
            flex-wrap: wrap;
        }
        .toolbar button {
            padding: 8px 12px;
            border: 1px solid #ccc;
            background: white;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
        }
        .toolbar button:hover {
            background: #e9e9e9;
        }
        .toolbar button.active {
            background: #007AFF;
            color: white;
        }
        #editor {
            min-height: 300px;
            outline: none;
            font-size: 16px;
            line-height: 1.6;
        }
        .newsletter-container {
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            font-family: 'Hiragino Sans', 'Yu Gothic', sans-serif;
            line-height: 1.6;
            background: white;
        }
        h1, h2, h3 { 
            color: #2c3e50; 
            margin-top: 20px; 
        }
        p { 
            margin-bottom: 12px; 
        }
        .header { 
            text-align: center; 
            border-bottom: 2px solid #3498db; 
            padding-bottom: 10px; 
        }
        .date { 
            text-align: right; 
            color: #7f8c8d; 
            font-size: 14px; 
        }
        .signature { 
            margin-top: 30px; 
            text-align: right; 
        }
    </style>
</head>
<body>
    <div class="toolbar">
        <button onclick="formatText('bold')">太字</button>
        <button onclick="formatText('italic')">斜体</button>
        <button onclick="formatText('underline')">下線</button>
        <button onclick="insertHeading(1)">見出し1</button>
        <button onclick="insertHeading(2)">見出し2</button>
        <button onclick="insertParagraph()">段落</button>
        <button onclick="getContent()">保存</button>
    </div>
    
    <div class="editor-container">
        <div id="editor" contenteditable="${widget.isEditable ? 'true' : 'false'}">
            $content
        </div>
    </div>

    <script>
        let editor = document.getElementById('editor');
        
        // 初期化
        document.addEventListener('DOMContentLoaded', function() {
            console.log('Mobile HTML Editor initialized');
            
            // Flutter側にロード完了を通知
            if (window.flutter_inappwebview) {
                window.flutter_inappwebview.callHandler('onEditorReady');
            }
        });

        // テキストフォーマット
        function formatText(command) {
            document.execCommand(command, false, null);
            editor.focus();
        }

        // 見出し挿入
        function insertHeading(level) {
            const selection = window.getSelection();
            if (selection.rangeCount > 0) {
                const range = selection.getRangeAt(0);
                const heading = document.createElement('h' + level);
                heading.textContent = selection.toString() || '見出し';
                
                range.deleteContents();
                range.insertNode(heading);
                range.selectNodeContents(heading);
                selection.removeAllRanges();
                selection.addRange(range);
            }
            editor.focus();
        }

        // 段落挿入
        function insertParagraph() {
            const selection = window.getSelection();
            if (selection.rangeCount > 0) {
                const range = selection.getRangeAt(0);
                const p = document.createElement('p');
                p.textContent = selection.toString() || '新しい段落';
                
                range.deleteContents();
                range.insertNode(p);
                range.selectNodeContents(p);
                selection.removeAllRanges();
                selection.addRange(range);
            }
            editor.focus();
        }

        // コンテンツ取得
        function getContent() {
            const content = editor.innerHTML;
            console.log('Editor content:', content);
            
            // Flutter側にコンテンツを送信
            if (window.flutter_inappwebview) {
                window.flutter_inappwebview.callHandler('onContentChanged', content);
            }
            
            return content;
        }

        // 自動保存（内容変更時）
        editor.addEventListener('input', function() {
            // デバウンス処理（500ms後に実行）
            clearTimeout(editor.saveTimeout);
            editor.saveTimeout = setTimeout(function() {
                const content = editor.innerHTML;
                if (window.flutter_inappwebview) {
                    window.flutter_inappwebview.callHandler('onContentChanged', content);
                }
            }, 500);
        });

        // コンテンツ設定
        function setContent(html) {
            editor.innerHTML = html;
        }

        // エディタ状態設定
        function setEditable(editable) {
            editor.contentEditable = editable;
        }
    </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ [CrossPlatformEditor] Building for ${PlatformService.platformName}');

    // Web版はHtmlWidgetPreviewを使用
    if (PlatformService.isWeb) {
      return HtmlWidgetPreview(
        htmlContent: widget.htmlContent,
        height: widget.height,
        onContentChanged: widget.onContentChanged,
        isEditable: widget.isEditable,
      );
    }

    // Mobile版はInAppWebViewを使用
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          InAppWebView(
            initialData: InAppWebViewInitialData(
              data: _buildMobileEditorHtml(_currentHtml),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              allowsInlineMediaPlayback: true,
              mediaPlaybackRequiresUserGesture: false,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
              
              // Flutter → JavaScript メッセージハンドラー
              controller.addJavaScriptHandler(
                handlerName: 'onEditorReady',
                callback: (args) {
                  debugPrint('📱 [Mobile Editor] Editor ready');
                  setState(() {
                    _isLoading = false;
                  });
                },
              );

              controller.addJavaScriptHandler(
                handlerName: 'onContentChanged',
                callback: (args) {
                  if (args.isNotEmpty) {
                    final content = args[0] as String;
                    debugPrint('📱 [Mobile Editor] Content changed: ${content.length} chars');
                    _currentHtml = content;
                    
                    if (widget.onContentChanged != null) {
                      widget.onContentChanged!(content);
                    }
                  }
                },
              );
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                _isLoading = false;
              });
            },
            onConsoleMessage: (controller, consoleMessage) {
              debugPrint('📱 [Mobile Editor Console] ${consoleMessage.message}');
            },
          ),
          
          // ローディングインジケーター
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}