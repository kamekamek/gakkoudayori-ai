import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'dart:convert';

/// HTMLプレビュー表示ウィジェット
class HtmlPreviewWidget extends StatefulWidget {
  final String htmlContent;
  final double height;

  const HtmlPreviewWidget({
    Key? key,
    required this.htmlContent,
    this.height = 400,
  }) : super(key: key);

  @override
  State<HtmlPreviewWidget> createState() => _HtmlPreviewWidgetState();
}

class _HtmlPreviewWidgetState extends State<HtmlPreviewWidget> {
  String? _viewId;
  web.HTMLIFrameElement? _iframe;
  String _cachedContent = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeHtmlView();
  }

  void _initializeHtmlView() {
    if (_viewId != null && _cachedContent == widget.htmlContent) {
      // キャッシュされたコンテンツと同じ場合は再作成しない
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _viewId = 'html-preview-${DateTime.now().millisecondsSinceEpoch}';
    _cachedContent = widget.htmlContent;

    // HTMLエレメントを作成
    _iframe = web.HTMLIFrameElement()
      ..width = '100%'
      ..height = '${widget.height.toInt()}px'
      ..style.width = '100%'
      ..style.height = '${widget.height}px'
      ..style.border = 'none'
      ..style.borderRadius = '8px'
      ..style.boxShadow = '0 2px 8px rgba(0,0,0,0.1)';

    // HTMLコンテンツを設定（完全なHTMLドキュメントとして）
    final fullHtml = '''
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>学級通信プレビュー</title>
    <style>
        body { 
            font-family: 'Hiragino Sans', 'Yu Gothic', sans-serif; 
            max-width: 800px; 
            margin: 0 auto; 
            padding: 20px; 
            line-height: 1.6;
            background-color: #fafafa;
        }
        h1, h2, h3 { color: #2c3e50; }
        .header { 
            text-align: center; 
            border-bottom: 2px solid #3498db; 
            padding-bottom: 10px; 
            margin-bottom: 20px; 
        }
        .footer { 
            text-align: center; 
            margin-top: 30px; 
            padding-top: 15px; 
            border-top: 1px solid #bdc3c7; 
            color: #7f8c8d; 
            font-size: 0.9em; 
        }
        .content { 
            background: white; 
            padding: 30px; 
            border-radius: 10px; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
        }
    </style>
</head>
<body>
    <div class="content" id="main-content">
        ${_extractHtmlContent(widget.htmlContent)}
    </div>
</body>
</html>''';

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

  /// 内容を動的に更新（iframe再作成なし）
  void _updateContent(String newContent) {
    if (_iframe?.contentWindow != null && newContent != _cachedContent) {
      try {
        final contentElement = _iframe!.contentDocument
            ?.getElementById('main-content') as web.HTMLElement?;
        if (contentElement != null) {
          final content = _extractHtmlContent(newContent);
          contentElement.innerHTML = content as dynamic;
          _cachedContent = newContent;
        }
      } catch (e) {
        print('📄 [HtmlPreview] 動的更新失敗、iframe再作成: $e');
        // 動的更新が失敗した場合は再作成
        _initializeHtmlView();
      }
    }
  }

  /// HTMLコンテンツから実際のコンテンツ部分を抽出
  String _extractHtmlContent(String htmlContent) {
    // ```html ``` 形式のマークアップを除去
    String cleaned =
        htmlContent.replaceAll('```html', '').replaceAll('```', '').trim();

    return cleaned.isEmpty ? '<p>プレビューコンテンツがありません</p>' : cleaned;
  }

  @override
  void didUpdateWidget(HtmlPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlContent != widget.htmlContent) {
      // キャッシュチェックして動的更新を試行
      if (_iframe != null && _viewId != null) {
        _updateContent(widget.htmlContent);
      } else {
        _initializeHtmlView();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_viewId == null) {
      return Container(
        height: widget.height,
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
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: HtmlElementView(
              viewType: _viewId!,
            ),
          ),
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
                      'プレビュー読み込み中...',
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
