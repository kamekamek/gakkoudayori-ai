import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import '../services/image_service.dart';

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
  final List<String>? availableImages;

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
    this.availableImages,
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
  List<String> _availableImages = [];

  // 通信用のメッセージハンドラ
  html.EventListener? _messageHandler;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initialTheme;
    _availableImages = widget.availableImages ?? [];
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
            } else if (data.startsWith('QUILL_READY')) {
              _handleQuillReady();
            }
          } else if (data is Map) {
            // オブジェクト形式のメッセージ
            if (data['type'] == 'REQUEST_IMAGE_INSERT') {
              _showImageSelector();
            } else if (data['type'] == 'IMAGE_DROPPED') {
              _handleImageDrop(data['fileCount']);
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
      if (kDebugMode) debugPrint('📝 [QuillEditor] 内容更新: ${html.length}文字');
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

      // TODO: postMessageでDelta取得を実装
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

  /// 画像を挿入
  Future<void> insertImage(String imageUrl, [String altText = '']) async {
    try {
      final iframeWindow = _iframeElement.contentWindow;
      if (iframeWindow == null) return;

      // JavaScript側の画像挿入関数を呼び出し
      iframeWindow.postMessage({
        'type': 'INSERT_IMAGE',
        'url': imageUrl,
        'altText': altText,
      }, '*');

      if (kDebugMode) debugPrint('📷 [QuillEditor] 画像挿入完了: $imageUrl');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [QuillEditor] 画像挿入エラー: $e');
    }
  }

  /// 複数画像の一括挿入
  Future<void> insertMultipleImages(List<String> imageUrls) async {
    try {
      final iframeWindow = _iframeElement.contentWindow;
      if (iframeWindow == null) return;

      final images = imageUrls.map((url) => {'url': url, 'altText': ''}).toList();

      iframeWindow.postMessage({
        'type': 'INSERT_MULTIPLE_IMAGES',
        'images': images,
      }, '*');

      if (kDebugMode) debugPrint('📷 [QuillEditor] 複数画像挿入完了: ${imageUrls.length}枚');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [QuillEditor] 複数画像挿入エラー: $e');
    }
  }

  /// 利用可能な画像リストを設定
  void setAvailableImages(List<String> imageUrls) {
    setState(() {
      _availableImages = imageUrls;
    });
  }

  /// 画像選択ダイアログ表示
  void _showImageSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📷 画像を挿入'),
        content: Container(
          width: 300,
          height: 400,
          child: _availableImages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('利用可能な画像がありません'),
                      SizedBox(height: 8),
                      Text(
                        '音声入力画面で画像をアップロードしてください',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _availableImages.length,
                  itemBuilder: (context, index) {
                    final imageUrl = _availableImages[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        insertImage(imageUrl);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[100],
                                child: Icon(Icons.error, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: _selectNewImage,
            child: Text('新しい画像を追加'),
          ),
        ],
      ),
    );
  }

  /// 新しい画像の選択・アップロード
  Future<void> _selectNewImage() async {
    try {
      Navigator.of(context).pop(); // ダイアログを閉じる

      final selectedFiles = await ImageService.selectImages(multiple: false);
      if (selectedFiles == null || selectedFiles.isEmpty) return;

      final file = selectedFiles.first;

      // アップロード処理
      final uploadResults = await ImageService.uploadImages(
        [file],
        'current_user_id', // 実際のユーザーIDを使用
      );

      if (uploadResults.isNotEmpty) {
        final imageUrl = uploadResults.first.url;
        _availableImages.add(imageUrl);

        // 画像をエディタに挿入
        await insertImage(imageUrl);
      }
    } catch (e) {
      _showError('画像アップロードエラー: $e');
    }
  }

  void _handleImageDrop(int fileCount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('画像のドラッグ&ドロップ機能は開発中です (${fileCount}枚)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// PDF生成要求処理
  void _requestPdfGeneration(String html) {
    // PDF生成機能は Phase R3-C で実装予定
    if (kDebugMode) debugPrint('📄 [QuillEditor] PDF生成要求受信 - HTML文字数: ${html.length}');

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
