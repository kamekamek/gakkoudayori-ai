import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'dart:convert';

/// A4印刷最適化プレビューウィジェット
/// 94_USER_FLOW_DESIGN.mdの印刷要件に準拠
class PrintPreviewWidget extends StatefulWidget {
  final String htmlContent;
  final double height;
  final bool enableMobilePrintView; // スマホでのA4印刷プレビュー強制表示

  const PrintPreviewWidget({
    Key? key,
    required this.htmlContent,
    required this.height,
    this.enableMobilePrintView = true,
  }) : super(key: key);

  @override
  State<PrintPreviewWidget> createState() => _PrintPreviewWidgetState();
}

class _PrintPreviewWidgetState extends State<PrintPreviewWidget> {
  String? _viewId;
  web.HTMLIFrameElement? _iframe;
  String _cachedContent = '';
  bool _isLoading = false;

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
    });

    _viewId = 'print-preview-${DateTime.now().millisecondsSinceEpoch}';
    _cachedContent = widget.htmlContent;

    // A4サイズに対応したiframe作成
    final safeHeight = widget.height;
    _iframe = web.HTMLIFrameElement()
      ..width = '100%'
      ..height = '${safeHeight.toInt()}px'
      ..style.width = '100%'
      ..style.height = '${safeHeight}px'
      ..style.border = 'none'
      ..style.borderRadius = '8px'
      ..style.boxShadow = '0 2px 8px rgba(0,0,0,0.1)';

    // A4印刷最適化HTMLコンテンツを作成
    final printOptimizedHtml = _createPrintOptimizedHtml(widget.htmlContent);

    final encodedHtml = Uri.dataFromString(
      printOptimizedHtml,
      mimeType: 'text/html',
      encoding: Encoding.getByName('utf-8')!,
    ).toString();

    _iframe!.src = encodedHtml;

    _iframe!.onLoad.listen((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId!,
      (int viewId) => _iframe!,
    );
  }

  /// A4印刷最適化HTMLを生成
  /// 94_USER_FLOW_DESIGN.mdの印刷要件に準拠した堅牢なレイアウト
  String _createPrintOptimizedHtml(String htmlContent) {
    final cleanedContent = _extractHtmlContent(htmlContent);

    return '''
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>学級通信 - 印刷プレビュー</title>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@300;400;500;700&display=swap" rel="stylesheet">
    <style>
        /* A4印刷最適化CSS - 元のスタイルを最大限保持 */
        
        /* 基本リセット（最小限） */
        * {
            box-sizing: border-box;
        }
        
        /* A4サイズの固定レイアウト（210mm × 297mm） */
        html, body {
            font-family: 'Noto Sans JP', 'Hiragino Sans', 'Yu Gothic', sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f5f5f5;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
        }
        
        /* 印刷用コンテナ - A4固定サイズ */
        .print-container {
            width: 210mm;
            min-height: 297mm;
            max-width: 210mm;
            margin: 20px auto;
            padding: 15mm;
            background: white;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
            position: relative;
        }
        
        /* 元のa4-sheetクラスがある場合の調整 */
        .a4-sheet {
            width: 100% !important;
            min-height: auto !important;
            margin: 0 !important;
            padding: 10mm !important;
            box-shadow: none !important;
        }
        
        /* フォントサイズとマージンの統一（PDF出力と同じ） */
        h1 {
            font-size: 18px !important;
            margin: 8px 0 !important;
            line-height: 1.2 !important;
        }
        
        h2 {
            font-size: 16px !important;
            margin: 6px 0 !important;
            line-height: 1.2 !important;
        }
        
        h3 {
            font-size: 14px !important;
            margin: 4px 0 !important;
            line-height: 1.2 !important;
        }
        
        p {
            font-size: 12px !important;
            line-height: 1.3 !important;
            margin: 3px 0 !important;
        }
        
        /* セクション間隔の最適化 */
        .section {
            margin-bottom: 8px !important;
            padding: 8px !important;
        }
        
        .content-section {
            margin-bottom: 6px !important;
            padding: 6px !important;
        }
        
        /* ヘッダー・フッターの最適化 */
        .newsletter-header {
            margin-bottom: 10px !important;
            padding: 8px !important;
        }
        
        .footer-note {
            margin-top: 10px !important;
            padding: 6px !important;
        }
        
        /* スマホでのA4プレビュー対応 */
        @media screen and (max-width: 768px) {
            .print-container {
                width: 100vw;
                min-height: auto;
                margin: 0;
                padding: 10mm;
                box-shadow: none;
            }
        }
        
        /* 印刷時の調整 */
        @media print {
            html, body {
                background: white !important;
            }
            
            .print-container {
                width: 100% !important;
                margin: 0 !important;
                padding: 0 !important;
                box-shadow: none !important;
            }
            
            .a4-sheet {
                box-shadow: none !important;
            }
        }
        
        /* 画像の最大幅制限 */
        img {
            max-width: 100% !important;
            height: auto !important;
        }
        
        /* テーブルの改ページ制御 */
        table {
            page-break-inside: avoid;
        }
        
        /* 改ページ制御 */
        .page-break {
            page-break-before: always;
        }
        
        .no-break {
            page-break-inside: avoid;
        }
    </style>
</head>
<body>
    <div class="print-container" id="main-content">
        ${cleanedContent}
    </div>
    
    <script>
        // 印刷プレビュー向けの追加処理
        document.addEventListener('DOMContentLoaded', function() {
            // 画像の最大幅を強制設定
            const images = document.querySelectorAll('img');
            images.forEach(img => {
                img.style.maxWidth = '100%';
                img.style.height = 'auto';
            });
            
            // テーブルの改ページ制御
            const tables = document.querySelectorAll('table');
            tables.forEach(table => {
                table.style.pageBreakInside = 'avoid';
            });
        });
    </script>
</body>
</html>
    ''';
  }

  /// HTMLコンテンツの抽出とサニタイズ
  String _extractHtmlContent(String htmlContent) {
    String cleaned =
        htmlContent.replaceAll('```html', '').replaceAll('```', '').trim();

    if (cleaned.isEmpty) {
      return '<p style="text-align: center; color: #999; margin: 50px 0;">プレビューコンテンツがありません</p>';
    }

    return cleaned;
  }

  /// 動的コンテンツ更新
  void _updatePrintContent(String newContent) {
    if (newContent != _cachedContent) {
      try {
        // CORSエラーを避けるため、iframe全体を再作成
        if (kDebugMode) debugPrint('🖨️ [PrintPreview] コンテンツ更新のためiframe再作成');
        _initializePrintPreview();
      } catch (e) {
        if (kDebugMode) debugPrint('🖨️ [PrintPreview] 動的更新失敗: $e');
        _initializePrintPreview();
      }
    }
  }

  @override
  void didUpdateWidget(PrintPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlContent != widget.htmlContent) {
      if (_iframe != null && _viewId != null) {
        _updatePrintContent(widget.htmlContent);
      } else {
        _initializePrintPreview();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (_viewId == null) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text(
                '印刷プレビュー準備中...',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
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
          // メインプレビュー
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: HtmlElementView(
              viewType: _viewId!,
            ),
          ),

          // モバイル用の操作ヒント
          if (isMobile && widget.enableMobilePrintView)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'スマホ最適化表示',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12, // スマホで読みやすいサイズに
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // ローディングオーバーレイ
          if (_isLoading)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      '印刷最適化プレビュー読み込み中...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      isMobile ? 'スマホでもA4印刷状態を再現' : 'A4サイズ印刷に最適化',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
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
