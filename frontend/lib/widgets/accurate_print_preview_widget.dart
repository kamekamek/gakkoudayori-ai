import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'dart:convert';
import '../utils/html_processing_utils.dart';

/// 正確なPDF印刷プレビューウィジェット
/// Playwrightでの印刷時と同じA4レイアウト・スタイルを再現
class AccuratePrintPreviewWidget extends StatefulWidget {
  final String htmlContent;
  final double scale;
  final bool showPageBorder;
  final Function(String)? onError;
  final VoidCallback? onContentReady;

  const AccuratePrintPreviewWidget({
    Key? key,
    required this.htmlContent,
    this.scale = 0.8, // A4ページをフィットさせるためのスケール
    this.showPageBorder = true,
    this.onError,
    this.onContentReady,
  }) : super(key: key);

  @override
  State<AccuratePrintPreviewWidget> createState() => _AccuratePrintPreviewWidgetState();
}

class _AccuratePrintPreviewWidgetState extends State<AccuratePrintPreviewWidget> {
  String? _viewId;
  web.HTMLIFrameElement? _iframe;
  String _cachedContent = '';
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // A4サイズの定数 (mmをpxに変換、96 DPI基準)
  static const double _a4WidthMm = 210.0;
  static const double _a4HeightMm = 297.0;
  static const double _mmToPx = 3.7795275591; // 96 DPI基準
  
  double get _a4WidthPx => _a4WidthMm * _mmToPx;
  double get _a4HeightPx => _a4HeightMm * _mmToPx;

  @override
  void initState() {
    super.initState();
    _initializePrintPreview();
  }

  void _initializePrintPreview() {
    if (_viewId != null && _cachedContent == widget.htmlContent) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // HTMLコンテンツの検証
      final validation = HtmlProcessingUtils.validateHtmlContent(widget.htmlContent);
      
      if (!validation['isValid']) {
        final issues = validation['issues'] as List<String>;
        throw Exception('印刷プレビュー用HTMLが無効: ${issues.join(', ')}');
      }

      _viewId = 'print-preview-${DateTime.now().millisecondsSinceEpoch}';
      _cachedContent = widget.htmlContent;

      // A4サイズのiframeを作成
      final scaledWidth = (_a4WidthPx * widget.scale).round();
      final scaledHeight = (_a4HeightPx * widget.scale).round();

      _iframe = web.HTMLIFrameElement()
        ..width = '${scaledWidth}px'
        ..height = '${scaledHeight}px'
        ..style.width = '${scaledWidth}px'
        ..style.height = '${scaledHeight}px'
        ..style.border = widget.showPageBorder ? '1px solid #ccc' : 'none'
        ..style.borderRadius = '4px'
        ..style.backgroundColor = '#ffffff'
        ..style.boxShadow = widget.showPageBorder 
            ? '0 4px 8px rgba(0,0,0,0.15)' 
            : 'none';

      // 印刷用フルHTMLドキュメントを生成
      final printHtml = _generatePrintHtml(widget.htmlContent);

      // HTMLをData URLとして設定
      final encodedHtml = Uri.dataFromString(
        printHtml,
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
          widget.onContentReady?.call();
          
          if (kDebugMode) {
            debugPrint('🖨️ [PrintPreview] A4印刷プレビュー読み込み完了');
          }
        }
      });

      // エラーハンドリング
      _iframe!.onError.listen((event) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = '印刷プレビューの読み込みに失敗しました';
          });
          widget.onError?.call(_errorMessage);
        }
      });

      // プラットフォームビューとして登録
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId!,
        (int viewId) => _iframe!,
      );

    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '印刷プレビューの初期化に失敗しました: $e';
      });
      widget.onError?.call(_errorMessage);
      
      if (kDebugMode) {
        debugPrint('🖨️ [PrintPreview] 初期化エラー: $e');
      }
    }
  }

  /// Playwrightと同じ印刷用HTMLを生成
  String _generatePrintHtml(String htmlContent) {
    final processedContent = HtmlProcessingUtils.extractAndSanitizeHtml(htmlContent);
    
    return '''
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <title>学級通信 - 印刷プレビュー</title>
    <style>
        @page {
            size: A4;
            margin: 15mm;
        }
        
        * {
            box-sizing: border-box;
        }
        
        html, body {
            margin: 0;
            padding: 0;
            width: 210mm;
            min-height: 297mm;
            font-family: 'Hiragino Sans', 'Yu Gothic', 'Noto Sans JP', sans-serif;
            font-size: 12pt;
            line-height: 1.5;
            color: #000;
            background: #fff;
        }
        
        body {
            padding: 15mm;
            display: block;
            overflow: visible;
        }
        
        /* ヘッダースタイル */
        h1 {
            font-size: 18pt;
            font-weight: bold;
            color: #000;
            text-align: center;
            margin: 0 0 15pt 0;
            padding-bottom: 10pt;
            border-bottom: 2pt solid #000;
            page-break-after: avoid;
        }
        
        h2 {
            font-size: 14pt;
            font-weight: bold;
            color: #000;
            margin: 20pt 0 10pt 0;
            padding: 8pt 12pt;
            background: #f0f0f0;
            border-left: 3pt solid #000;
            page-break-after: avoid;
        }
        
        h3 {
            font-size: 12pt;
            font-weight: bold;
            color: #000;
            margin: 15pt 0 8pt 0;
            page-break-after: avoid;
        }
        
        /* テキストスタイル */
        p {
            margin: 8pt 0;
            text-align: justify;
            orphans: 2;
            widows: 2;
        }
        
        ul, ol {
            margin: 10pt 0;
            padding-left: 20pt;
        }
        
        li {
            margin: 6pt 0;
            line-height: 1.4;
        }
        
        strong {
            font-weight: bold;
            color: #000;
        }
        
        em {
            font-style: italic;
        }
        
        /* テーブルスタイル */
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 10pt 0;
            page-break-inside: avoid;
        }
        
        th, td {
            border: 1pt solid #000;
            padding: 6pt;
            text-align: left;
        }
        
        th {
            background-color: #f0f0f0;
            font-weight: bold;
        }
        
        /* 特殊クラス */
        .header {
            text-align: center;
            border-bottom: 2pt solid #000;
            padding-bottom: 10pt;
            margin-bottom: 20pt;
        }
        
        .footer {
            text-align: center;
            margin-top: 25pt;
            padding-top: 10pt;
            border-top: 1pt solid #000;
            font-size: 10pt;
        }
        
        .date-info {
            text-align: center;
            font-size: 11pt;
            margin: 8pt 0 15pt 0;
        }
        
        .author-info {
            text-align: right;
            font-size: 11pt;
            margin-top: 20pt;
            font-style: italic;
        }
        
        /* 印刷時の色指定 */
        .highlight {
            background-color: #f0f0f0 !important;
            padding: 2pt 4pt;
        }
        
        .important {
            font-weight: bold;
        }
        
        /* ページ区切り */
        .page-break {
            page-break-before: always;
        }
        
        .no-break {
            page-break-inside: avoid;
        }
        
        /* 隠し要素 */
        .no-print {
            display: none !important;
        }
        
        /* リンクスタイル */
        a {
            color: #000;
            text-decoration: none;
        }
        
        a:after {
            content: " (" attr(href) ")";
            font-size: 9pt;
            color: #666;
        }
        
        /* 画像調整 */
        img {
            max-width: 100%;
            height: auto;
            page-break-inside: avoid;
        }
        
        /* フォントサイズの統一 */
        small {
            font-size: 10pt;
        }
        
        /* マージン調整 */
        .content-wrapper {
            width: 100%;
            height: auto;
            overflow: visible;
        }
    </style>
</head>
<body>
    <div class="content-wrapper">
        $processedContent
    </div>
</body>
</html>''';
  }

  /// コンテンツを動的に更新
  void _updateContent(String newContent) {
    if (_iframe?.contentWindow != null && newContent != _cachedContent) {
      try {
        final printHtml = _generatePrintHtml(newContent);
        
        final encodedHtml = Uri.dataFromString(
          printHtml,
          mimeType: 'text/html',
          encoding: Encoding.getByName('utf-8')!,
        ).toString();

        _iframe!.src = encodedHtml;
        _cachedContent = newContent;

        if (kDebugMode) {
          debugPrint('🖨️ [PrintPreview] 印刷プレビュー動的更新完了');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('🖨️ [PrintPreview] 動的更新失敗、再初期化: $e');
        }
        _initializePrintPreview();
      }
    }
  }

  @override
  void didUpdateWidget(AccuratePrintPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlContent != widget.htmlContent) {
      if (_iframe != null && _viewId != null) {
        _updateContent(widget.htmlContent);
      } else {
        _initializePrintPreview();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaledWidth = (_a4WidthPx * widget.scale);
    final scaledHeight = (_a4HeightPx * widget.scale);

    if (_hasError) {
      return _buildErrorState(scaledWidth, scaledHeight);
    }

    if (_viewId == null) {
      return _buildLoadingState(scaledWidth, scaledHeight);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            // プレビューヘッダー
            Container(
              width: scaledWidth,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.print, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'A4印刷プレビュー',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${(widget.scale * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // A4プレビュー
            Container(
              width: scaledWidth,
              height: scaledHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                    child: HtmlElementView(
                      viewType: _viewId!,
                    ),
                  ),
                  if (_isLoading) _buildLoadingOverlay(),
                ],
              ),
            ),
            
            // フッター情報
            const SizedBox(height: 12),
            Text(
              'A4サイズ (210×297mm) - PDF出力と同じ表示',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '印刷プレビューを準備中...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'レンダリング中...',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.print_disabled,
                size: 32,
                color: Colors.red[400],
              ),
              const SizedBox(height: 8),
              Text(
                '印刷プレビューエラー',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _errorMessage,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                  });
                  _initializePrintPreview();
                },
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('再試行'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}