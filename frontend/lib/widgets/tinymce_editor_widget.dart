import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:convert';

/// TinyMCE WYSIWYGエディタウィジェット (Flutter Web版)
/// ユーザーフレンドリーなWordライクなエディタ
class TinyMCEEditorWidget extends StatefulWidget {
  final String? initialContent;
  final Function(String html)? onContentChanged;
  final Function()? onEditorReady;
  final double height;
  final String initialTheme;

  const TinyMCEEditorWidget({
    Key? key,
    this.initialContent,
    this.onContentChanged,
    this.onEditorReady,
    this.height = 600,
    this.initialTheme = 'spring',
  }) : super(key: key);

  @override
  State<TinyMCEEditorWidget> createState() => _TinyMCEEditorWidgetState();
}

class _TinyMCEEditorWidgetState extends State<TinyMCEEditorWidget> {
  late html.IFrameElement _iframeElement;
  bool _isLoading = true;
  String _currentContent = '';
  String _currentTheme = 'spring';
  final String _viewType = 'tinymce-editor-iframe';

  // 通信用のメッセージハンドラ
  html.EventListener? _messageHandler;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initialTheme;
    _initializeIframe();
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

  /// iframeを初期化してTinyMCE HTMLファイルを読み込み
  void _initializeIframe() {
    // TinyMCE HTMLコンテンツをData URLとして埋め込み
    final htmlContent = _getTinyMCEHtmlContent();
    final dataUrl = 'data:text/html;charset=utf-8,${Uri.encodeComponent(htmlContent)}';
    
    // iframeエレメント作成
    _iframeElement = html.IFrameElement()
      ..src = dataUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '${widget.height}px';

    // iframe読み込み完了イベント
    _iframeElement.onLoad.listen((_) {
      print('📝 [TinyMCE] iframeが読み込まれました');
      
      // 初期コンテンツが指定されている場合は設定
      if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
        Future.delayed(Duration(milliseconds: 1000), () {
          setContent(widget.initialContent!);
        });
      }
    });

    // プラットフォームビューとして登録
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframeElement,
    );
  }

  /// Flutter ↔ TinyMCE間のメッセージ通信をセットアップ
  void _setupMessageListener() {
    _messageHandler = (html.Event event) {
      final messageEvent = event as html.MessageEvent;
      
      try {
        final data = messageEvent.data;
        final message = data is String ? jsonDecode(data) : data;
        
        if (message is Map<String, dynamic>) {
          _handleMessage(message);
        }
      } catch (e) {
        print('❌ [TinyMCE] メッセージ解析エラー: $e');
      }
    };

    html.window.addEventListener('message', _messageHandler!);
  }

  /// TinyMCEからのメッセージを処理
  void _handleMessage(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'tinymce_ready':
        print('✅ [TinyMCE] エディタ準備完了');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        
        // 季節テーマを適用
        setTheme(_currentTheme);
        
        // 準備完了コールバック
        if (widget.onEditorReady != null) {
          widget.onEditorReady!();
        }
        break;

      case 'content_changed':
        final content = message['data']?['html'] as String?;
        if (content != null && content != _currentContent) {
          _currentContent = content;
          
          // コンテンツ変更コールバック
          if (widget.onContentChanged != null) {
            widget.onContentChanged!(content);
          }
        }
        break;

      case 'content_response':
        final content = message['data']?['html'] as String?;
        if (content != null) {
          _currentContent = content;
        }
        break;

      default:
        print('🔍 [TinyMCE] 未知のメッセージタイプ: ${message['type']}');
    }
  }

  /// TinyMCEにメッセージを送信
  void _sendMessage(Map<String, dynamic> message) {
    try {
      final contentWindow = _iframeElement.contentWindow;
      if (contentWindow != null) {
        contentWindow.postMessage(jsonEncode(message), '*');
      }
    } catch (e) {
      print('❌ [TinyMCE] メッセージ送信エラー: $e');
    }
  }

  /// エディタのコンテンツを設定
  void setContent(String html) {
    _sendMessage({
      'type': 'set_content',
      'data': {'html': html}
    });
  }

  /// エディタのコンテンツを取得
  void getContent() {
    _sendMessage({
      'type': 'get_content',
      'data': {}
    });
  }

  /// 季節テーマを設定
  void setTheme(String theme) {
    _currentTheme = theme;
    _sendMessage({
      'type': 'set_theme',
      'data': {'theme': theme}
    });
  }

  /// テキストを挿入
  void insertText(String text) {
    _sendMessage({
      'type': 'insert_text',
      'data': {'text': text}
    });
  }

  /// AI生成コンテンツを挿入
  void insertAIContent(String content) {
    // AIが生成したHTMLコンテンツを挿入
    setContent(content);
  }

  /// TinyMCE用のHTMLコンテンツを生成
  String _getTinyMCEHtmlContent() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>TinyMCE Editor</title>
    <script src="https://cdn.jsdelivr.net/npm/tinymce@6.8.3/tinymce.min.js"></script>
</head>
<body style="margin:0;padding:10px;font-family:Arial,sans-serif;">
    <div id="status" style="text-align:center;padding:20px;color:#666;">
        📝 エディタを読み込み中...
    </div>
    
    <textarea id="editor">
        <h1>🌸 学級通信 🌸</h1>
        <p>こんにちは、保護者の皆様。</p>
        <p>今日は素晴らしい一日でした。子どもたちの笑顔がとても印象的でした。</p>
        
        <h2>📚 今日の学習</h2>
        <ul>
            <li>国語：漢字の練習をしました</li>
            <li>算数：かけ算の基礎を学びました</li>
            <li>体育：みんなで楽しく運動しました</li>
        </ul>
        
        <h2>📝 お知らせ</h2>
        <p>明日は遠足です。お弁当の準備をお願いします。</p>
    </textarea>

    <script>
        console.log('🚀 TinyMCE Data URL版 開始');
        
        if (typeof tinymce === 'undefined') {
            document.getElementById('status').innerHTML = '❌ TinyMCE読み込み失敗';
            console.error('TinyMCE未定義');
        } else {
            console.log('✅ TinyMCE読み込み成功');
            document.getElementById('status').innerHTML = '✅ 初期化中...';
            
            tinymce.init({
                selector: '#editor',
                height: 400,
                menubar: false,
                plugins: ['lists', 'link', 'paste', 'autoresize'],
                toolbar: 'undo redo | bold italic | bullist numlist | link',
                paste_as_text: true,
                autoresize_bottom_margin: 16,
                
                init_instance_callback: function(editor) {
                    console.log('✅ TinyMCE初期化完了');
                    document.getElementById('status').style.display = 'none';
                    
                    // Flutter側に通知
                    if (window.parent && window.parent.postMessage) {
                        window.parent.postMessage({
                            type: 'tinymce_ready',
                            data: { status: 'ready' }
                        }, '*');
                        console.log('Flutter側に準備完了通知送信');
                    }
                    
                    // コンテンツ変更イベント
                    editor.on('change keyup', function() {
                        const content = editor.getContent();
                        if (window.parent && window.parent.postMessage) {
                            window.parent.postMessage({
                                type: 'content_changed',
                                data: { html: content }
                            }, '*');
                        }
                    });
                }
            }).catch(function(error) {
                console.error('TinyMCE初期化エラー:', error);
                document.getElementById('status').innerHTML = '❌ 初期化失敗: ' + error.message;
            });
        }
        
        // メッセージ受信
        window.addEventListener('message', function(event) {
            try {
                const message = typeof event.data === 'string' ? JSON.parse(event.data) : event.data;
                
                if (message.type === 'set_content' && tinymce.activeEditor) {
                    tinymce.activeEditor.setContent(message.data.html || '');
                } else if (message.type === 'get_content' && tinymce.activeEditor) {
                    const content = tinymce.activeEditor.getContent();
                    window.parent.postMessage({
                        type: 'content_response',
                        data: { html: content }
                    }, '*');
                }
            } catch (e) {
                console.error('メッセージエラー:', e);
            }
        });
    </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // TinyMCEエディタ
            HtmlElementView(
              viewType: _viewType,
            ),
            
            // ローディングインジケータ
            if (_isLoading)
              Container(
                color: Colors.white.withValues(alpha: 0.9),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.blue[600],
                      ),
                      SizedBox(height: 16),
                      Text(
                        '📝 エディタを準備中...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Wordのような編集画面が表示されます',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// TinyMCEエディタのテーマ定数
class TinyMCETheme {
  static const String spring = 'spring';
  static const String summer = 'summer';
  static const String autumn = 'autumn';
  static const String winter = 'winter';
  
  static const Map<String, String> themeNames = {
    spring: '🌸 春',
    summer: '🌻 夏', 
    autumn: '🍁 秋',
    winter: '⛄ 冬',
  };
  
  static const Map<String, Color> primaryColors = {
    spring: Color(0xFF8ED1FC),
    summer: Color(0xFFFFD93D),
    autumn: Color(0xFFFF9234),
    winter: Color(0xFF87CEEB),
  };
}