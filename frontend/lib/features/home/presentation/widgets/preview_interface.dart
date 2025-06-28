import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'dart:html' as html;
import '../../../editor/providers/preview_provider.dart';
import '../../providers/newsletter_provider.dart';
import '../../../ai_assistant/providers/adk_chat_provider.dart';
import 'preview_mode_toolbar.dart';
import '../../../../widgets/quill_editor_widget.dart';

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
    return Container(
      color: const Color(0xFFFAFAFA),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2c5aa0).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description,
                  size: 48,
                  color: Color(0xFF2c5aa0),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '📄 プレビュー',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2c5aa0),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'リアルタイムプレビューがここに表示されます',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF616161),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'AIとの対話を開始してください',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
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

  Widget _buildEditMode(BuildContext context, String htmlContent) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              '編集モード',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '高速で安定したQuillエディタを\n別ウィンドウで開きます',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _openQuillEditor(context),
              icon: const Icon(Icons.open_in_new, size: 20),
              label: const Text('Quillエディタを開く'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
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

  void _regenerateContent(BuildContext context) async {
    final previewProvider = context.read<PreviewProvider>();
    final adkChatProvider = context.read<AdkChatProvider>();
    
    if (previewProvider.htmlContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('再生成するコンテンツがありません')),
      );
      return;
    }
    
    try {
      // PreviewProviderの再生成処理を開始
      await previewProvider.regenerateContent();
      
      // 既存コンテンツの要約を取得（PreviewProvider内で解析済み）
      final contentSummary = previewProvider.extractContentSummary(previewProvider.htmlContent);
      
      // Open_SuperAgent風の再生成プロンプト作成
      final regenerationPrompt = '''
現在の学級通信を改善してください：

【現在の内容】
$contentSummary

【要求】
- 同じテーマと構造を維持しながら、内容をより魅力的に書き直してください
- 読みやすさと親しみやすさを向上させてください
- 重要な情報は残しつつ、表現を改善してください
- HTMLフォーマットで生成してください

学級通信の内容を再生成してください。
''';
      
      // ADKChatProviderに再生成を依頼
      adkChatProvider.sendMessage(regenerationPrompt);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔄 コンテンツの再生成を開始しました...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 再生成に失敗しました: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _openQuillEditor(BuildContext context) {
    html.window.open('/quill/', '_blank');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📝 Quillエディタを新しいタブで開きました'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final previewProvider =
        Provider.of<PreviewProvider>(context, listen: false);
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('HTMLコンテンツの編集'),
              content: SizedBox(
                width: double.maxFinite,
                child: QuillEditorWidget(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () => _openQuillEditor(context),
                  child: const Text('開く'),
                ),
              ],
            ));
  }
}
