import 'package:flutter/material.dart';
import 'dart:convert';
// Web API一時無効化
// import 'package:web/web.dart' as web;
import '../../../../core/services/api_service.dart';

/// PDF出力ウィジェット
///
/// エディタのHTMLコンテンツをPDFに変換し、
/// ダウンロード可能にします。
class PDFExportWidget extends StatefulWidget {
  final String htmlContent;
  final String title;
  final VoidCallback? onExportStart;
  final VoidCallback? onExportComplete;
  final Function(String error)? onError;

  const PDFExportWidget({
    Key? key,
    required this.htmlContent,
    this.title = '学級通信',
    this.onExportStart,
    this.onExportComplete,
    this.onError,
  }) : super(key: key);

  @override
  State<PDFExportWidget> createState() => _PDFExportWidgetState();
}

class _PDFExportWidgetState extends State<PDFExportWidget>
    with TickerProviderStateMixin {
  bool _isGenerating = false;
  String _status = '';
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _generatePDF() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _status = 'PDF生成中...';
    });

    _progressController.repeat();
    widget.onExportStart?.call();

    try {
      final result = await _apiService.generatePDF(
        htmlContent: widget.htmlContent,
        title: widget.title,
        pageSize: 'A4',
        margin: '20mm',
        includeHeader: true,
        includeFooter: true,
      );

      if (result['success']) {
        setState(() {
          _status = 'PDF生成完了！ダウンロード中...';
        });

        // Base64データからPDFダウンロード
        final pdfBase64 = result['data']['pdf_base64'];
        await _downloadPDF(pdfBase64, widget.title);

        setState(() {
          _status = 'PDF出力完了';
          _isGenerating = false;
        });

        _progressController.stop();
        _progressController.reset();
        widget.onExportComplete?.call();

        // 成功メッセージ表示
        _showSuccessDialog(result['data']);
      } else {
        throw Exception(result['error'] ?? 'PDF生成に失敗しました');
      }
    } catch (e) {
      setState(() {
        _status = 'PDF生成エラー';
        _isGenerating = false;
      });

      _progressController.stop();
      _progressController.reset();

      final errorMessage = 'PDF生成中にエラーが発生しました: $e';
      widget.onError?.call(errorMessage);
      _showErrorDialog(errorMessage);
    }
  }

  Future<void> _downloadPDF(String base64Data, String title) async {
    try {
      // TODO: Web API対応が完了するまで一時的にアラート表示
      // ignore: avoid_web_libraries_in_flutter
      // Web API一時無効化 - PDF機能は後で実装
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'PDF出力機能は準備中です（データサイズ: ${(base64Data.length / 1024).toStringAsFixed(1)}KB）'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      throw Exception('PDFダウンロードに失敗しました: $e');
    }
  }

  void _showSuccessDialog(Map<String, dynamic> pdfData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        title: const Text('PDF出力完了'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${widget.title}」のPDF出力が完了しました。'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📄 ファイルサイズ: ${pdfData['file_size_mb']} MB'),
                  Text('📑 ページ数: ${pdfData['page_count']}'),
                  Text('⏱️ 処理時間: ${pdfData['processing_time_ms']}ms'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.error,
          color: Colors.red,
          size: 48,
        ),
        title: const Text('PDF出力エラー'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ヘッダー
            Row(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red.shade600,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PDF出力',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '学級通信をPDFファイルとして保存',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 進行状況表示
            if (_isGenerating) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: null,
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue.shade600,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _status,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // PDF出力ボタン
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generatePDF,
              icon: Icon(
                _isGenerating ? Icons.hourglass_empty : Icons.download,
              ),
              label: Text(
                _isGenerating ? 'PDF生成中...' : 'PDFとして出力',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 説明文
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PDFの特徴:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...[
                    '✅ A4サイズで印刷に最適化',
                    '✅ 季節テーマカラー対応',
                    '✅ ヘッダー・フッター自動挿入',
                    '✅ 日本語フォント最適化',
                  ].map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
