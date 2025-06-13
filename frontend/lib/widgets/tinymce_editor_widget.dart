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
    // iframeエレメント作成
    _iframeElement = html.IFrameElement()
      ..src = '/tinymce/index.html'
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