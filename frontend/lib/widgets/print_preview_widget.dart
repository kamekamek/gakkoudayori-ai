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
    final safeHeight = widget.height.isFinite ? widget.height : 600.0;
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
    <style>
        /* A4印刷最適化CSS - CLASIC_LAYOUT.mdの堅牢性原則準拠 */
        
        /* 基本リセット */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        /* A4サイズの固定レイアウト（210mm × 297mm） */
        html, body {
            font-family: 'Hiragino Sans', 'Yu Gothic', 'Noto Sans JP', sans-serif;
            font-size: 14px;
            line-height: 1.6;
            color: #333;
            background-color: #ffffff;
            margin: 0;
            padding: 0;
        }
        
        /* 印刷用コンテナ - A4固定サイズ */
        .print-container {
            width: 210mm;
            min-height: 297mm;
            max-width: 210mm;
            margin: 0 auto;
            padding: 20mm;
            background: white;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
            
            /* 絶対にシングルカラム - 崩れ防止 */
            display: block !important;
            float: none !important;
            position: static !important;
        }
        
        /* スマホでのA4プレビュー対応 - 視認性改善版 */
        @media (max-width: 768px) {
            .print-container {
                /* スマホでは実用的な幅に調整 */
                width: 100vw;
                max-width: 100vw;
                min-width: unset;
                transform: none; /* 縮小をやめて読みやすさを優先 */
                transform-origin: unset;
                margin: 0;
                margin-bottom: 0;
                padding: 16px; /* スマホ用のパディング */
            }
            
            /* スマホでのスクロール対応 */
            body {
                overflow-x: auto;
                overflow-y: auto;
            }
            
            /* スマホ用フォントサイズ調整 */
            .print-container {
                font-size: 16px; /* スマホで読みやすいサイズ */
                line-height: 1.7;
            }
            
            .print-container h1 {
                font-size: 20px !important;
            }
            
            .print-container h2 {
                font-size: 18px !important;
            }
            
            .print-container h3 {
                font-size: 16px !important;
            }
        }
        
        /* 印刷時のレイアウト固定 */
        @media print {
            .print-container {
                width: 100% !important;
                max-width: none !important;
                margin: 0 !important;
                padding: 15mm !important;
                box-shadow: none !important;
                transform: none !important;
            }
            
            /* 印刷時の改ページ制御 */
            .print-container * {
                page-break-inside: avoid !important;
            }
        }
        
        /* コンテンツスタイル - 堅牢性重視 */
        .print-container h1,
        .print-container h2,
        .print-container h3 {
            color: #2c3e50;
            margin-bottom: 10px;
            margin-top: 20px;
            font-weight: bold;
            line-height: 1.4;
            
            /* 見出しの崩れ防止 */
            display: block !important;
            float: none !important;
            clear: both !important;
        }
        
        .print-container h1 {
            font-size: 18px;
            border-bottom: 2px solid #3498db;
            padding-bottom: 5px;
        }
        
        .print-container h2 {
            font-size: 16px;
            color: #34495e;
        }
        
        .print-container h3 {
            font-size: 14px;
            color: #7f8c8d;
        }
        
        .print-container p {
            margin-bottom: 10px;
            text-align: justify;
            orphans: 3;
            widows: 3;
        }
        
        .print-container ul,
        .print-container ol {
            margin-bottom: 15px;
            padding-left: 20px;
        }
        
        .print-container li {
            margin-bottom: 5px;
        }
        
        /* 表・画像の堅牢化 */
        .print-container table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 15px;
        }
        
        .print-container img {
            max-width: 100% !important;
            height: auto !important;
            display: block;
            margin: 10px auto;
        }
        
        /* 複雑なレイアウトの強制シンプル化 */
        .print-container .newsletter-container,
        .print-container .complex-layout {
            display: block !important;
            width: 100% !important;
            max-width: 100% !important;
            float: none !important;
            position: static !important;
            margin: 0 !important;
            padding: 0 !important;
        }
        
        /* 既存のスタイルを上書きして崩れを防止 */
        .print-container * {
            max-width: 100% !important;
            box-sizing: border-box !important;
        }
        
        /* フレックス・グリッドレイアウトの無効化 */
        .print-container .flex-container,
        .print-container .grid-container {
            display: block !important;
        }
        
        /* カラム分割の無効化 */
        .print-container .columns {
            column-count: 1 !important;
            column-gap: 0 !important;
        }
        
        /* Loading状態の非表示 */
        .loading-overlay {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(255,255,255,0.9);
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.2);
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
            // すべての要素のmax-widthを強制設定
            const allElements = document.querySelectorAll('*');
            allElements.forEach(el => {
                el.style.maxWidth = '100%';
                el.style.boxSizing = 'border-box';
            });
            
            // 複雑なレイアウトの強制シンプル化
            const containers = document.querySelectorAll('.newsletter-container, .flex-container, .grid-container');
            containers.forEach(container => {
                container.style.display = 'block';
                container.style.width = '100%';
                container.style.float = 'none';
                container.style.position = 'static';
            });
        });
    </script>
</body>
</html>''';
  }

  /// HTMLコンテンツの抽出とサニタイズ
  String _extractHtmlContent(String htmlContent) {
    String cleaned = htmlContent
        .replaceAll('```html', '')
        .replaceAll('```', '')
        .trim();

    if (cleaned.isEmpty) {
      return '<p style="text-align: center; color: #999; margin: 50px 0;">プレビューコンテンツがありません</p>';
    }

    return cleaned;
  }

  /// 動的コンテンツ更新
  void _updatePrintContent(String newContent) {
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
        print('🖨️ [PrintPreview] 動的更新失敗、iframe再作成: $e');
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
    final safeHeight = widget.height.isFinite ? widget.height : 600.0;
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (_viewId == null) {
      return Container(
        height: safeHeight,
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
      height: safeHeight,
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