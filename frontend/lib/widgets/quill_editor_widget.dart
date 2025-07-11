import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

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
    _removeMessageListener();
    super.dispose();
  }

  void _setupMessageListener() {
    _messageHandler = (html.Event event) {
      if (event is html.MessageEvent) {
        try {
          // メッセージデータを解析
          final data = event.data;
          if (data is String) {
            // 文字列形式のメッセージ
            if (data.startsWith('QUILL_HTML:')) {
              final html = data.substring('QUILL_HTML:'.length);
              _handleHtmlUpdate(html);
            } else if (data.startsWith('QUILL_DELTA:')) {
              final deltaJson = data.substring('QUILL_DELTA:'.length);
              _handleDeltaUpdate(deltaJson);
            } else if (data.startsWith('QUILL_READY')) {
              _handleQuillReady();
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('❌ [QuillEditor] メッセージ処理エラー: $e');
        }
      }
    };

    html.window.addEventListener('message', _messageHandler!);
  }

  void _removeMessageListener() {
    if (_messageHandler != null) {
      html.window.removeEventListener('message', _messageHandler!);
      _messageHandler = null;
    }
  }

  void _handleHtmlUpdate(String html) {
    if (mounted) {
      _currentContent = html;
      widget.onContentChanged?.call(html);
      widget.onHtmlReady?.call(html);
      if (kDebugMode) debugPrint('📝 [QuillEditor] 内容更新: ${html.length}文字');
    }
  }

  void _handleDeltaUpdate(String deltaJson) {
    if (mounted) {
      widget.onDeltaChanged?.call(deltaJson);
      if (kDebugMode)
        debugPrint('📝 [QuillEditor] Delta更新: ${deltaJson.length}文字');
    }
  }

  void _handleQuillReady() {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      widget.onEditorReady?.call();
      if (kDebugMode) debugPrint('📝 [QuillBridge] Quill.js 準備完了');
    }
  }

  void _initializeIframe() {
    try {
      // 安全な高さの計算
      final safeHeight = widget.height.isFinite ? widget.height : 500.0;

      // iframeElement作成
      _iframeElement = html.IFrameElement()
        ..width = '100%'
        ..height = '${safeHeight.toInt()}px'
        ..src = 'quill/index.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

      // iframe読み込み完了イベント
      _iframeElement.onLoad.listen((_) {
        if (kDebugMode) debugPrint('✅ [QuillEditor] iframe読み込み完了');
        _initializeContent();
        // ローディング状態は QUILL_READY メッセージで制御
      });

      // platformViewRegistryに登録
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => _iframeElement,
      );

      if (kDebugMode) debugPrint('🔗 [QuillEditor] iframe初期化完了');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [QuillEditor] iframe初期化エラー: $e');
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
        if (kDebugMode) debugPrint('❌ [QuillEditor] iframe window取得失敗');
        return;
      }

      // iframe内のquillSetContent関数を呼び出し
      final escapedContent =
          content.replaceAll("'", "\\'").replaceAll('\n', '\\n');
      final script =
          "if(window.quillSetContent) window.quillSetContent('$escapedContent', '$format');";

      // 直接スクリプト実行（より安定）
      iframeWindow.postMessage("EXEC:$script", "*");

      if (kDebugMode) debugPrint('📝 [QuillEditor] 内容設定完了 ($format形式)');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [QuillEditor] 内容設定エラー: $e');
    }
  }

  /// HTML取得
  Future<String> getHtml() async {
    try {
      final iframeWindow = _iframeElement.contentWindow;
      if (iframeWindow == null) return '';

      // 直接スクリプト実行
      iframeWindow.postMessage("EXEC:window.quillGetHtml();", "*");

      // 現在の内容を返す（非同期で更新される）
      return _currentContent;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [QuillEditor] HTML取得エラー: $e');
      return '';
    }
  }

  /// Delta取得
  Future<String> getDelta() async {
    try {
      final iframeWindow = _iframeElement.contentWindow;
      if (iframeWindow == null) return '';

      // JavaScript側のquillGetDelta関数を呼び出し
      final script = '''
        try {
          const delta = window.quillGetDelta();
          window.parent.postMessage('QUILL_DELTA:' + delta, '*');
        } catch (e) {
          console.error('Delta取得エラー:', e);
        }
      ''';

      iframeWindow.postMessage("EXEC:$script", "*");

      if (kDebugMode) debugPrint('📝 [QuillEditor] Delta取得要求送信');

      // 非同期で結果は _handleDeltaUpdate で受信
      return '';
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [QuillEditor] Delta取得エラー: $e');
      return '';
    }
  }

  /// 内容をクリア
  Future<void> clearContent() async {
    try {
      final iframeWindow = _iframeElement.contentWindow;
      if (iframeWindow == null) return;

      iframeWindow.postMessage("EXEC:window.quillClear();", "*");

      if (kDebugMode) debugPrint('🗑️ [QuillEditor] 内容クリア完了');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [QuillEditor] クリアエラー: $e');
    }
  }

  /// 季節テーマを変更
  Future<void> switchTheme(String theme) async {
    try {
      final iframeWindow = _iframeElement.contentWindow;
      if (iframeWindow == null) return;

      iframeWindow.postMessage("EXEC:window.quillSwitchTheme('$theme');", "*");

      _currentTheme = theme;
      if (kDebugMode) debugPrint('🎨 [QuillEditor] テーマ変更: $theme');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [QuillEditor] テーマ変更エラー: $e');
    }
  }

  /// PDF生成要求処理
  void _requestPdfGeneration(String html) {
    // PDF生成機能は Phase R3-C で実装予定
    if (kDebugMode)
      debugPrint('📄 [QuillEditor] PDF生成要求受信 - HTML文字数: ${html.length}');

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
    final safeHeight = widget.height.isFinite ? widget.height : 500.0;
    return SizedBox(
      height: safeHeight,
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : HtmlElementView(viewType: _viewType),
    );
  }
}
