import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

/// リッチHTMLエディターウィジェット
/// contenteditableを使用してHTML構造を保持しながら編集可能
class RichHtmlEditorWidget extends StatefulWidget {
  final String initialContent;
  final Function(String html)? onContentChanged;
  final double height;
  final bool showToolbar;

  const RichHtmlEditorWidget({
    Key? key,
    required this.initialContent,
    this.onContentChanged,
    this.height = 500,
    this.showToolbar = true,
  }) : super(key: key);

  @override
  State<RichHtmlEditorWidget> createState() => _RichHtmlEditorWidgetState();
}

class _RichHtmlEditorWidgetState extends State<RichHtmlEditorWidget> {
  late html.IFrameElement _iframeElement;
  late String _viewType;
  String _currentHtml = '';
  bool _isReady = false;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _currentHtml = _sanitizeAndPrepareHtml(widget.initialContent);
    _viewType = 'rich-html-editor-${DateTime.now().millisecondsSinceEpoch}';
    _setupHtmlEditor();
  }

  /// HTML編集用のiframeを設定
  void _setupHtmlEditor() {
    _iframeElement = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';

    // Platform view registry に登録
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframeElement,
    );

    // iframe の読み込み完了を待ってからエディターを初期化
    _iframeElement.onLoad.listen((_) {
      _initializeEditor();
    });

    // エディター用のHTMLドキュメントを設定
    _iframeElement.srcdoc = _createEditorHtml();
  }

  /// エディター用のHTMLドキュメントを作成
  String _createEditorHtml() {
    return '''
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rich HTML Editor</title>
    <style>
        body {
            margin: 0;
            padding: 16px;
            font-family: 'Hiragino Sans', 'Yu Gothic', 'Noto Sans JP', sans-serif;
            line-height: 1.6;
            background-color: #fff;
        }
        
        .editor-container {
            width: 100%;
            min-height: 400px;
            border: 1px solid #e0e0e0;
            border-radius: 8px;
            padding: 16px;
            outline: none;
            background: white;
        }
        
        .editor-container:focus {
            border-color: #2196F3;
            box-shadow: 0 0 0 2px rgba(33, 150, 243, 0.2);
        }
        
        /* 既存のHTMLスタイルを保持 */
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
        
        /* 編集中のスタイル */
        .editing-indicator {
            position: fixed;
            top: 10px;
            right: 10px;
            background: #ff9800;
            color: white;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            opacity: 0;
            transition: opacity 0.3s;
        }
        
        .editing-indicator.show {
            opacity: 1;
        }
        
        /* 選択時のハイライト */
        ::selection {
            background-color: #e3f2fd;
        }
    </style>
</head>
<body>
    <div id="editing-indicator" class="editing-indicator">編集中...</div>
    <div 
        id="editor" 
        class="editor-container" 
        contenteditable="true"
        spellcheck="false"
    >
        ${_currentHtml}
    </div>
    
    <script>
        const editor = document.getElementById('editor');
        const indicator = document.getElementById('editing-indicator');
        let isModified = false;
        let saveTimeout;
        
        // 編集イベントの監視
        editor.addEventListener('input', function() {
            isModified = true;
            indicator.classList.add('show');
            
            // 自動保存のためのタイマー
            clearTimeout(saveTimeout);
            saveTimeout = setTimeout(function() {
                saveContent();
            }, 1000); // 1秒後に自動保存
        });
        
        // フォーカス時のイベント
        editor.addEventListener('focus', function() {
            this.style.borderColor = '#2196F3';
        });
        
        // フォーカス離脱時のイベント
        editor.addEventListener('blur', function() {
            this.style.borderColor = '#e0e0e0';
            if (isModified) {
                saveContent();
            }
        });
        
        // 保存処理
        function saveContent() {
            if (isModified) {
                const content = editor.innerHTML;
                // Flutter側に通知
                if (window.parent && window.parent.postMessage) {
                    window.parent.postMessage({
                        type: 'contentChanged',
                        content: content
                    }, '*');
                }
                isModified = false;
                indicator.classList.remove('show');
            }
        }
        
        // キーボードショートカット
        editor.addEventListener('keydown', function(e) {
            // Ctrl+S で保存
            if ((e.ctrlKey || e.metaKey) && e.key === 's') {
                e.preventDefault();
                saveContent();
            }
            
            // Ctrl+B で太字
            if ((e.ctrlKey || e.metaKey) && e.key === 'b') {
                e.preventDefault();
                document.execCommand('bold');
            }
            
            // Ctrl+I で斜体
            if ((e.ctrlKey || e.metaKey) && e.key === 'i') {
                e.preventDefault();
                document.execCommand('italic');
            }
        });
        
        // エディター初期化完了を通知
        window.addEventListener('load', function() {
            if (window.parent && window.parent.postMessage) {
                window.parent.postMessage({
                    type: 'editorReady'
                }, '*');
            }
        });
        
        // 外部からのコンテンツ更新を受信
        window.addEventListener('message', function(event) {
            if (event.data.type === 'updateContent') {
                editor.innerHTML = event.data.content;
                isModified = false;
                indicator.classList.remove('show');
            }
        });
    </script>
</body>
</html>''';
  }

  /// エディターの初期化
  void _initializeEditor() {
    if (kDebugMode) {
      debugPrint('🖊️ [RichHtmlEditor] エディター初期化開始');
    }

    // iframe内のpostMessageを監視
    html.window.addEventListener('message', _handleMessage);
  }

  /// メッセージハンドラー（dispose時に解除するため分離）
  void _handleMessage(html.Event event) {
    // dispose後はイベント処理しない
    if (!mounted) return;

    final messageEvent = event as html.MessageEvent;
    final data = messageEvent.data;
    if (data is Map) {
      if (data['type'] == 'editorReady') {
        if (mounted) {
          setState(() {
            _isReady = true;
          });
          if (kDebugMode) {
            debugPrint('🖊️ [RichHtmlEditor] エディター準備完了');
          }
        }
      } else if (data['type'] == 'contentChanged') {
        final content = data['content'] as String?;
        if (content != null && content != _currentHtml && mounted) {
          _currentHtml = content;
          _isModified = true;
          
          // 相互更新ループを防ぐため、少し遅延させる
          Future.microtask(() {
            if (mounted) {
              widget.onContentChanged?.call(content);
              if (kDebugMode) {
                debugPrint('🖊️ [RichHtmlEditor] コンテンツ更新: ${content.length}文字');
              }
            }
          });
        }
      }
    }
  }

  /// HTMLをサニタイズして編集用に準備
  String _sanitizeAndPrepareHtml(String html) {
    if (html.trim().isEmpty) {
      return '<p>ここに学級通信の内容を入力してください...</p>';
    }

    // 危険なタグの除去
    String sanitized = html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
        .replaceAll(RegExp(r'<iframe[^>]*>.*?</iframe>', dotAll: true), '')
        .replaceAll(RegExp(r'<object[^>]*>.*?</object>', dotAll: true), '')
        .replaceAll(RegExp(r'<embed[^>]*>', dotAll: true), '');

    // 基本的なHTMLバリデーション
    if (!sanitized.contains('<') || !sanitized.contains('>')) {
      // プレーンテキストの場合は段落に変換
      final lines = sanitized.split('\n');
      final htmlLines = lines.where((line) => line.trim().isNotEmpty)
          .map((line) => '<p>${line.trim()}</p>')
          .join('\n');
      return htmlLines.isNotEmpty ? htmlLines : '<p>ここに学級通信の内容を入力してください...</p>';
    }

    return sanitized;
  }

  /// コンテンツを外部から更新
  void updateContent(String html) {
    final sanitized = _sanitizeAndPrepareHtml(html);
    if (sanitized != _currentHtml && mounted) {
      _currentHtml = sanitized;
      if (_isReady && _iframeElement.contentWindow != null) {
        try {
          _iframeElement.contentWindow!.postMessage({
            'type': 'updateContent',
            'content': sanitized
          }, '*');
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ [RichHtmlEditor] コンテンツ更新エラー: $e');
          }
        }
      }
    }
  }

  /// ツールバーのボタンを作成
  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive ? Colors.blue.shade100 : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 18,
              color: isActive ? Colors.blue.shade700 : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  /// フォーマット用ツールバー
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          const Text(
            'リッチHTMLエディター',
            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          
          _buildToolbarButton(
            icon: Icons.format_bold,
            tooltip: '太字 (Ctrl+B)',
            onPressed: () => _executeCommand('bold'),
          ),
          
          _buildToolbarButton(
            icon: Icons.format_italic,
            tooltip: '斜体 (Ctrl+I)',
            onPressed: () => _executeCommand('italic'),
          ),
          
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: Colors.grey.shade300),
          const SizedBox(width: 8),
          
          _buildToolbarButton(
            icon: Icons.format_list_bulleted,
            tooltip: '箇条書き',
            onPressed: () => _executeCommand('insertUnorderedList'),
          ),
          
          _buildToolbarButton(
            icon: Icons.format_list_numbered,
            tooltip: '番号付きリスト',
            onPressed: () => _executeCommand('insertOrderedList'),
          ),
          
          const Spacer(),
          
          if (_isModified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '未保存',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// エディター コマンドの実行
  void _executeCommand(String command) {
    if (_isReady && _iframeElement.contentWindow != null) {
      js.context['execCommand'] = (String cmd) {
        _iframeElement.contentWindow!.postMessage({
          'type': 'execCommand',
          'command': cmd
        }, '*');
      };
      js.context.callMethod('execCommand', [command]);
    }
  }

  @override
  void didUpdateWidget(RichHtmlEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialContent != widget.initialContent) {
      updateContent(widget.initialContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (widget.showToolbar) _buildToolbar(),
          
          Expanded(
            child: Stack(
              children: [
                if (kIsWeb)
                  HtmlElementView(viewType: _viewType)
                else
                  const Center(
                    child: Text(
                      'リッチHTMLエディターはWeb版でのみ利用可能です',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                
                if (!_isReady)
                  Container(
                    color: Colors.white.withOpacity(0.8),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'エディターを準備中...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('🖊️ [RichHtmlEditor] エディター破棄');
    }
    
    // イベントリスナーを確実に削除
    try {
      html.window.removeEventListener('message', _handleMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [RichHtmlEditor] イベントリスナー削除エラー: $e');
      }
    }
    
    super.dispose();
  }
}