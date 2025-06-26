import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'dart:html' as html;
import '../../../editor/providers/preview_provider.dart';
import '../../providers/newsletter_provider.dart';
import '../../../ai_assistant/providers/adk_chat_provider.dart';
import 'preview_mode_toolbar.dart';
import '../../../../widgets/quill_editor_widget.dart';
import '../../../../widgets/inline_editable_text_widget.dart';
import '../../../../mock/classroom_post_mock.dart';

/// プレビューインターフェース（右側パネル）
class PreviewInterface extends StatelessWidget {
  const PreviewInterface({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<PreviewProvider, NewsletterProvider, AdkChatProvider>(
      builder: (context, previewProvider, newsletterProvider, chatProvider, child) {
        return Column(
          children: [
            // プレビューモード切り替えツールバー
            PreviewModeToolbar(
              currentMode: previewProvider.currentMode,
              onModeChanged: (mode) => previewProvider.switchMode(mode),
              onPdfGenerate: () {
            context.read<PreviewProvider>().generatePdf(context);
          },
              onPrintPreview: () => _showPrintPreview(context),
              onRegenerate: () => _regenerateContent(context),
              onClassroomPost: chatProvider.isDemo ? () => _postToClassroom(context) : null,
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
                  chatProvider,
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
    AdkChatProvider chatProvider,
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
        return _buildEditMode(context, previewProvider, chatProvider);

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

  Widget _buildEditMode(BuildContext context, PreviewProvider previewProvider, AdkChatProvider chatProvider) {
    // デモモードの場合はインライン編集可能なプレビューを表示
    if (chatProvider.isDemo && previewProvider.htmlContent.isNotEmpty) {
      return InlineEditableHtmlPreview(
        htmlContent: previewProvider.htmlContent,
        onHtmlChanged: (newHtml) {
          previewProvider.updateHtmlContent(newHtml);
        },
        isDemo: true,
      );
    }

    // 通常モードまたはコンテンツが空の場合は従来の編集モード
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
              chatProvider.isDemo 
                  ? 'デモモードではインライン編集が利用できます\n学級通信を生成してから編集モードをお試しください'
                  : '高速で安定したQuillエディタを\n別ウィンドウで開きます',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!chatProvider.isDemo)
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
      await context.read<PreviewProvider>().generatePdf(context);
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
    context.read<NewsletterProvider>().generateNewsletter();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('コンテンツの再生成を実行します。')),
    );
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

  void _postToClassroom(BuildContext context) async {
    final previewProvider = context.read<PreviewProvider>();
    final htmlContent = previewProvider.htmlContent;
    
    if (htmlContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('投稿する学級通信が生成されていません'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 投稿プレビューダイアログを表示
    ClassroomPostMock.showPostPreviewDialog(
      context,
      htmlContent: htmlContent,
      title: '学級通信「みんなでがんばろう」- ${DateTime.now().month}月${DateTime.now().day}日',
      description: 'AI生成学級通信をお送りします。ご確認ください。',
      onConfirm: () => _executeClassroomPost(context, htmlContent),
    );
  }

  void _executeClassroomPost(BuildContext context, String htmlContent) async {
    try {
      // 投稿処理中の表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Google Classroomに投稿中...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // モック投稿実行
      final result = await ClassroomPostMock.postNewsletter(
        htmlContent: htmlContent,
        title: '学級通信「みんなでがんばろう」- ${DateTime.now().month}月${DateTime.now().day}日',
        description: 'AI生成学級通信をお送りします。ご確認ください。',
      );

      if (result.success) {
        // 投稿成功ダイアログを表示
        ClassroomPostMock.showPostSuccessDialog(context, result);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Classroom投稿に失敗しました: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
