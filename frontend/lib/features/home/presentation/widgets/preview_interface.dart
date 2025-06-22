import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../../editor/providers/preview_provider.dart';
import '../../providers/newsletter_provider.dart';
import 'preview_mode_toolbar.dart';

/// プレビューインターフェース（右側パネル）
class PreviewInterface extends StatelessWidget {
  const PreviewInterface({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PreviewProvider, NewsletterProvider>(
      builder: (context, previewProvider, newsletterProvider, child) {
        return Column(
          children: [
            // プレビューモード切り替えツールバー
            PreviewModeToolbar(
              currentMode: previewProvider.currentMode,
              onModeChanged: (mode) => previewProvider.switchMode(mode),
              onPdfGenerate: () => _generatePdf(context),
              onPrintPreview: () => _showPrintPreview(context),
              onRegenerate: () => _regenerateContent(context),
              canExecuteActions: previewProvider.htmlContent.isNotEmpty,
            ),

            // プレビューコンテンツ
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.background,
                child: _buildPreviewContent(
                  context,
                  previewProvider,
                  newsletterProvider,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewContent(
    BuildContext context,
    PreviewProvider previewProvider,
    NewsletterProvider newsletterProvider,
  ) {
    // 生成中の場合
    if (previewProvider.isGeneratingPdf) {
      return _buildLoadingState(context, 'PDF生成中...');
    }

    // コンテンツがない場合
    if (previewProvider.htmlContent.isEmpty) {
      return _buildEmptyState(context);
    }

    // プレビューモードに応じて表示
    switch (previewProvider.currentMode) {
      case PreviewMode.preview:
        return _buildPreviewMode(context, previewProvider.htmlContent);
      
      case PreviewMode.edit:
        return _buildEditMode(context, previewProvider.htmlContent);
      
      case PreviewMode.printView:
        return _buildPrintViewMode(context, previewProvider.htmlContent);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.preview,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '学級通信のプレビュー',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AIとの会話後に「生成」ボタンを押すと、\nこちらに学級通信が表示されます',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, String statusMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AI生成中...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewMode(BuildContext context, String htmlContent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: HtmlWidget(
            htmlContent,
            textStyle: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildEditMode(BuildContext context, String htmlContent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 編集ツールバー
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '編集モード',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        context.read<PreviewProvider>().switchMode(PreviewMode.preview);
                      },
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('保存'),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 編集可能コンテンツ（仮実装）
              HtmlWidget(
                htmlContent,
                textStyle: Theme.of(context).textTheme.bodyMedium,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                '💡 編集機能は開発中です。現在はプレビューのみ対応しています。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrintViewMode(BuildContext context, String htmlContent) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Container(
          width: 595, // A4幅 (210mm * 2.83 ≈ 595px)
          height: 842, // A4高さ (297mm * 2.83 ≈ 842px)
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: HtmlWidget(
              htmlContent,
              textStyle: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _generatePdf(BuildContext context) async {
    try {
      await context.read<PreviewProvider>().generatePdf();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ PDFを生成しました'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ PDF生成に失敗しました: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showPrintPreview(BuildContext context) async {
    try {
      await context.read<PreviewProvider>().showPrintPreview();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 印刷プレビューの表示に失敗しました: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _regenerateContent(BuildContext context) {
    context.read<NewsletterProvider>().generateNewsletter('classic');
  }
}