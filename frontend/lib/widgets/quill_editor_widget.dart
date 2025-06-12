import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:js' as js;

/// Quill.js WYSIWYGエディタウィジェット (Flutter Web版)
/// HtmlElementViewとiframeを使用してQuill.js HTMLファイルを表示
class QuillEditorWidget extends StatefulWidget {
  final String? initialContent;
  final String contentFormat; // 'html' or 'delta'
  final Function(String html)? onContentChanged;
  final Function(String html)? onHtmlReady;
  final Function(String deltaJson)? onDeltaChanged;
  final Function()? onEditorReady;
  final double height;
  final String initialTheme;

  const QuillEditorWidget({
    Key? key,
    this.initialContent,
    this.contentFormat = 'html',
    this.onContentChanged,
    this.onHtmlReady,
    this.onDeltaChanged,
    this.onEditorReady,
    this.height = 500,
    this.initialTheme = 'spring',
  }) : super(key: key);

  @override
  State<QuillEditorWidget> createState() => _QuillEditorWidgetState();
}

class _QuillEditorWidgetState extends State<QuillEditorWidget> {
  late html.IFrameElement _iframeElement;
  bool _isLoading = true;
  String _currentContent = '';
  String _currentTheme = 'spring';
  final String _viewType = 'quill-editor-iframe';

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initialTheme;
    _initializeIframe();
  }

  void _initializeIframe() {
    try {
      // iframeElement作成
      _iframeElement = html.IFrameElement()
        ..width = '100%'
        ..height = '100%'
        ..src = 'quill/index.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

      // iframe読み込み完了イベント
      _iframeElement.onLoad.listen((_) {
        print('✅ [QuillEditor] iframe読み込み完了');
        _setupJavaScriptBridge();
        _initializeContent();

        // 🔥 mounted チェック追加でメモリリーク防止
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });

      // platformViewRegistryに登録
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => _iframeElement,
      );

      print('🔗 [QuillEditor] iframe初期化完了');
    } catch (e) {
      print('❌ [QuillEditor] iframe初期化エラー: $e');
    }
  }

  void _setupJavaScriptBridge() {
    try {
      // Flutter → iframe Bridge設定

      // iframe内のwindowオブジェクトを取得
      final iframeWindow = _iframeElement.contentWindow;
      if (iframeWindow == null) {
        print('❌ [QuillEditor] iframe contentWindow取得失敗');
        return;
      }

      // Flutter側のコールバック関数をグローバルに設定
      js.context['onQuillReady'] = js.allowInterop(() {
        print('📝 [QuillBridge] Quill.js 準備完了');
        widget.onEditorReady?.call();
      });

      js.context['onQuillContentChanged'] = js.allowInterop((data) {
        try {
          // JSオブジェクトをDartオブジェクトに変換
          final dartData = _jsObjectToDart(data);
          final html = dartData['html'] as String;
          final wordCount = dartData['wordCount'] as int;

          _currentContent = html;
          widget.onContentChanged?.call(html);

          print('📝 [QuillEditor] 内容更新: ${wordCount}文字');
        } catch (e) {
          print('❌ [QuillEditor] コンテンツ変更処理エラー: $e');
        }
      });

      js.context['onQuillHtmlChanged'] = js.allowInterop((html) {
        widget.onHtmlReady?.call(html);
      });

      js.context['onQuillDeltaChanged'] = js.allowInterop((deltaJson) {
        widget.onDeltaChanged?.call(deltaJson);
      });

      js.context['onQuillPdfRequest'] = js.allowInterop((html) {
        _requestPdfGeneration(html);
      });

      print('🔗 [QuillEditor] JavaScript Bridge設定完了');
    } catch (e) {
      print('❌ [QuillEditor] Bridge設定エラー: $e');
    }
  }

  // JSオブジェクトをDartマップに変換するヘルパー
  Map<String, dynamic> _jsObjectToDart(dynamic jsObject) {
    if (jsObject == null) return {};

    try {
      // JS objectをJSONに変換してからDartオブジェクトにパース
      final jsonString = js.context.callMethod('JSON.stringify', [jsObject]);
      return jsonDecode(jsonString);
    } catch (e) {
      print('⚠️ [QuillEditor] JSオブジェクト変換エラー: $e');
      return {};
    }
  }

  void _initializeContent() {
    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      // 少し遅延してから設定（iframe準備待ち）
      Future.delayed(Duration(milliseconds: 500), () {
        // 🔥 mounted チェック追加でメモリリーク防止
        if (mounted) {
          setContent(widget.initialContent!, widget.contentFormat);
        }
      });
    }
  }

  // 外部から呼び出し可能なメソッド

  /// 内容を設定
  Future<void> setContent(String content, [String format = 'html']) async {
    try {
      final iframeWindow = _iframeElement.contentWindow;
      if (iframeWindow == null) {
        print('❌ [QuillEditor] iframe window取得失敗');
        return;
      }

      // iframe内のquillSetContent関数を呼び出し
      final escapedContent =
          content.replaceAll("'", "\\'").replaceAll('\n', '\\n');
      final script =
          "if(window.quillSetContent) window.quillSetContent('$escapedContent', '$format');";

      iframeWindow.postMessage({'type': 'evalScript', 'script': script}, '*');

      print('📝 [QuillEditor] 内容設定完了 ($format形式)');
    } catch (e) {
      print('❌ [QuillEditor] 内容設定エラー: $e');
    }
  }

  /// HTML取得
  Future<String> getHtml() async {
    try {
      final iframeWindow = _iframeElement.contentWindow;
      if (iframeWindow == null) return '';

      // TODO: postMessageでHTML取得を実装
      return _currentContent;
    } catch (e) {
      print('❌ [QuillEditor] HTML取得エラー: $e');
      return '';
    }
  }

  /// Delta取得
  Future<String> getDelta() async {
    try {
      final iframeWindow = _iframeElement.contentWindow;
      if (iframeWindow == null) return '';

      // TODO: postMessageでDelta取得を実装
      return '';
    } catch (e) {
      print('❌ [QuillEditor] Delta取得エラー: $e');
      return '';
    }
  }

  /// 内容をクリア
  Future<void> clearContent() async {
    try {
      final iframeWindow = _iframeElement.contentWindow;
      if (iframeWindow == null) return;

      iframeWindow.postMessage({
        'type': 'evalScript',
        'script': 'if(window.quillClear) window.quillClear();'
      }, '*');

      print('🗑️ [QuillEditor] 内容クリア完了');
    } catch (e) {
      print('❌ [QuillEditor] クリアエラー: $e');
    }
  }

  /// 季節テーマを変更
  Future<void> switchTheme(String theme) async {
    try {
      final iframeWindow = _iframeElement.contentWindow;
      if (iframeWindow == null) return;

      iframeWindow.postMessage({
        'type': 'evalScript',
        'script':
            "if(window.quillSwitchTheme) window.quillSwitchTheme('$theme');"
      }, '*');

      _currentTheme = theme;
      print('🎨 [QuillEditor] テーマ変更: $theme');
    } catch (e) {
      print('❌ [QuillEditor] テーマ変更エラー: $e');
    }
  }

  /// PDF生成要求処理
  void _requestPdfGeneration(String html) {
    // PDF生成機能は Phase R3-C で実装予定
    print('📄 [QuillEditor] PDF生成要求受信 - HTML文字数: ${html.length}');

    // 将来的にはPDFサービスに送信
    // PdfService.generateFromHtml(html);

    // 現在は簡易的なHTML出力
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📄 PDF出力'),
        content: Text('PDF出力機能は実装予定です。\n現在はHTML形式でダウンロードできます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // HtmlElementView本体
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: HtmlElementView(
              viewType: _viewType,
            ),
          ),

          // ローディング表示
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '📝 Quill.js エディタ読み込み中...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
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

  @override
  void dispose() {
    // クリーンアップ
    try {
      js.context.deleteProperty('onQuillReady');
      js.context.deleteProperty('onQuillContentChanged');
      js.context.deleteProperty('onQuillHtmlChanged');
      js.context.deleteProperty('onQuillDeltaChanged');
      js.context.deleteProperty('onQuillPdfRequest');
    } catch (e) {
      print('⚠️ [QuillEditor] クリーンアップエラー: $e');
    }
    super.dispose();
  }
}
