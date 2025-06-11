import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'quill_editor_web.dart' if (dart.library.html) 'quill_editor_web.dart' if (dart.library.io) 'quill_editor_stub.dart';
import '../../services/javascript_bridge.dart';

/// Quill.jsエディタを統合したWebViewウィジェット
class QuillEditorWidget extends StatefulWidget {
  final String? initialContent;
  final Function(String content)? onContentChanged;
  final Function(Map<String, dynamic> selection)? onSelectionChanged;
  final Function()? onReady;

  const QuillEditorWidget({
    super.key,
    this.initialContent,
    this.onContentChanged,
    this.onSelectionChanged,
    this.onReady,
  });

  @override
  State<QuillEditorWidget> createState() => QuillEditorWidgetState();
}

/// Public state class for external access to editor methods
class QuillEditorWidgetState extends State<QuillEditorWidget> {
  dynamic _iframe;
  bool _isLoading = true;
  String? _errorMessage;
  late final JavaScriptBridge _bridge;

  @override
  void initState() {
    super.initState();
    _bridge = JavaScriptBridge();
    _initializeIframe();
  }

  void _initializeIframe() {
    if (!kIsWeb) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'このウィジェットはWeb環境でのみ動作します';
      });
      return;
    }

    try {
      _iframe = QuillEditorWebImplementation.createIFrame();

      // IFrame読み込み完了イベント
      _iframe.onLoad.listen((_) {
        setState(() {
          _isLoading = false;
        });
        _setupJavaScriptChannels();
      });

      // IFrameをFlutterウィジェットとして登録
      QuillEditorWebImplementation.iframe = _iframe;
      QuillEditorWebImplementation.registerViewFactory();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'IFrame初期化エラー: $e';
      });
    }
  }

  void _setupJavaScriptChannels() {
    try {
      final iframeWindow = _iframe.contentWindow;
      if (iframeWindow == null) return;

      // Quill準備完了を待つ
      _waitForQuillReady();
    } catch (e) {
      debugPrint('JavaScript channel setup error: $e');
    }
  }

  void _waitForQuillReady() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_isQuillReady()) {
        debugPrint('Quill editor ready');
        _initializeContent();
        widget.onReady?.call();
        _setupContentChangeListener();
      } else {
        _waitForQuillReady(); // 再帰的に待機
      }
    });
  }

  bool _isQuillReady() {
    try {
      final iframeWindow = _iframe.contentWindow;
      if (iframeWindow == null) return false;
      
      final result = iframeWindow.eval('window.quillBridge && window.quillBridge.ping()');
      return result?.toString().contains('pong') == true;
    } catch (e) {
      return false;
    }
  }

  void _setupContentChangeListener() {
    // Note: Full content change monitoring would require more complex iframe communication
    // For now, we'll implement basic functionality
  }

  void _initializeContent() {
    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      setHTML(widget.initialContent!);
    }
  }

  /// Bridge経由でコマンドを実行
  Future<JavaScriptResponse> _executeCommand(JavaScriptCommand command) async {
    try {
      final iframeWindow = _iframe?.contentWindow;
      if (iframeWindow == null) {
        return _bridge.createErrorResponse('IFrame not available');
      }
      
      final commandJson = _bridge.serializeCommand(command);
      final resultJson = iframeWindow.eval('window.quillBridge.executeCommand(\'$commandJson\')');
      
      if (resultJson != null) {
        return _bridge.deserializeResponse(resultJson.toString());
      } else {
        return _bridge.createErrorResponse('No response from bridge');
      }
    } catch (e) {
      debugPrint('Bridge command error: $e');
      return _bridge.createErrorResponse('Bridge execution failed: $e', id: command.id);
    }
  }

  /// エディタのHTML内容を取得
  Future<String?> getHTML() async {
    final response = await _executeCommand(QuillCommands.getHTML());
    return response.success ? response.data?.toString() : null;
  }

  /// エディタにHTML内容を設定
  Future<void> setHTML(String html) async {
    await _executeCommand(QuillCommands.setHTML(html));
  }

  /// エディタのDeltaを取得
  Future<String?> getDelta() async {
    final response = await _executeCommand(QuillCommands.getDelta());
    return response.success ? response.data?.toString() : null;
  }

  /// エディタにDeltaを設定
  Future<void> setDelta(String deltaJson) async {
    await _executeCommand(QuillCommands.setDelta(deltaJson));
  }

  /// エディタのテキストのみを取得
  Future<String?> getText() async {
    final response = await _executeCommand(QuillCommands.getText());
    return response.success ? response.data?.toString() : null;
  }

  /// エディタにテキストを挿入
  Future<void> insertText(String text, {int? index}) async {
    await _executeCommand(QuillCommands.insertText(text, index: index));
  }

  /// エディタにフォーカス
  Future<void> focus() async {
    await _executeCommand(QuillCommands.focus());
  }

  /// 選択範囲を取得
  Future<String?> getSelection() async {
    final response = await _executeCommand(QuillCommands.getSelection());
    return response.success ? response.data?.toString() : null;
  }

  /// 選択範囲を設定
  Future<void> setSelection(int index, int length) async {
    await _executeCommand(QuillCommands.setSelection(index, length));
  }

  /// 季節テーマを設定
  Future<void> setTheme(String themeName) async {
    await _executeCommand(QuillCommands.setTheme(themeName));
  }

  /// 接続テスト
  Future<bool> ping() async {
    final response = await _executeCommand(QuillCommands.ping());
    return response.success && response.data?.toString().contains('pong') == true;
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'エディタの読み込みに失敗しました',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _initializeIframe();
              },
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: kIsWeb 
            ? HtmlElementView(viewType: QuillEditorWebImplementation.viewType)
            : Container(
                color: Colors.grey[100],
                child: const Center(
                  child: Text('Web環境でのみ利用可能'),
                ),
              ),
        ),
        if (_isLoading)
          Container(
            color: Colors.white.withOpacity(0.8),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('エディタを読み込み中...'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}