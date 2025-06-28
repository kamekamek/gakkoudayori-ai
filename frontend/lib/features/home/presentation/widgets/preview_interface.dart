import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;
import '../../../editor/providers/preview_provider.dart';
import '../../providers/newsletter_provider.dart';
import '../../../ai_assistant/providers/adk_chat_provider.dart';
import 'preview_mode_toolbar.dart';
import '../../../../widgets/quill_editor_widget.dart';
import '../../../../widgets/notification_widget.dart';
import '../../../../widgets/unified_preview_widget.dart';
import '../../../../widgets/accurate_print_preview_widget.dart';
import '../../../../widgets/simple_html_editor_widget.dart';
import '../../../../widgets/rich_html_editor_widget.dart';
import '../../../../utils/html_processing_utils.dart';
import '../../../../core/models/chat_message.dart';

/// プレビューインターフェース（右側パネル）
class PreviewInterface extends StatefulWidget {
  const PreviewInterface({super.key});

  @override
  State<PreviewInterface> createState() => _PreviewInterfaceState();
}

class _PreviewInterfaceState extends State<PreviewInterface> {
  final List<NotificationData> _notifications = [];

  void _addNotification(String message, SystemMessageType type) {
    final notification = NotificationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      type: type,
    );

    setState(() {
      _notifications.add(notification);
    });

    // 自動削除タイマー
    Future.delayed(const Duration(seconds: 5), () {
      _removeNotification(notification.id);
    });
  }

  void _removeNotification(String id) {
    setState(() {
      _notifications.removeWhere((notification) => notification.id == id);
    });
  }

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
              onNotification: _addNotification,
            ),

            // 通知エリア
            if (_notifications.isNotEmpty)
              NotificationContainer(
                notifications: _notifications,
                onDismiss: _removeNotification,
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
        return _buildUnifiedPreviewMode(context, previewProvider.htmlContent);

      case PreviewMode.edit:
        return _buildInlineEditMode(context, previewProvider);

      case PreviewMode.printView:
        return _buildAccuratePrintViewMode(context, previewProvider.htmlContent);
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

  Widget _buildInlineEditMode(BuildContext context, PreviewProvider previewProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 編集モードのヘッダー
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'リッチHTML編集モード',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openQuillEditor(context),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Quill'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showLegacyEditor(context, previewProvider),
                  icon: const Icon(Icons.text_fields, size: 14),
                  label: const Text('旧'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          
          // インライン編集エリア（新しいRichHtmlEditor使用）
          Expanded(
            child: RichHtmlEditorWidget(
              key: ValueKey('rich-editor-${previewProvider.hashCode}'),
              initialContent: HtmlProcessingUtils.sanitizeForRichEditor(previewProvider.htmlContent),
              onContentChanged: (editedHtml) {
                // 相互更新ループを防ぐため、内容が実際に変わった場合のみ処理
                if (editedHtml == previewProvider.htmlContent) return;
                
                // HTML構造の検証と変更検出
                final changes = HtmlProcessingUtils.detectHtmlChanges(
                  previewProvider.htmlContent, 
                  editedHtml
                );
                
                try {
                  // デバウンス的な処理で連続更新を防ぐ
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted && editedHtml != previewProvider.htmlContent) {
                      previewProvider.updateHtmlContent(editedHtml);
                      
                      if (changes['hasChanges']) {
                        final changeDetails = changes['details'] as String;
                        _addNotification('✅ $changeDetails', SystemMessageType.success);
                        
                        // 構造的変更がある場合は特別な通知
                        if (changes['hasStructuralChanges']) {
                          final structuralChanges = changes['structuralChanges'] as List<String>;
                          _addNotification('🔄 ${structuralChanges.join(', ')}', SystemMessageType.info);
                        }
                      }
                    }
                  });
                } catch (e) {
                  _addNotification('❌ 編集内容の保存に失敗: $e', SystemMessageType.error);
                }
              },
              height: 400, // 適切な高さに変更
              showToolbar: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedPreviewMode(BuildContext context, String htmlContent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: UnifiedPreviewWidget(
          htmlContent: htmlContent,
          height: 600,
          onContentReady: () {
            if (mounted) {
              _addNotification('プレビューの準備が完了しました', SystemMessageType.success);
            }
          },
          onError: (error) {
            if (mounted) {
              _addNotification('プレビューエラー: $error', SystemMessageType.error);
            }
          },
        ),
      ),
    );
  }

  Widget _buildAccuratePrintViewMode(BuildContext context, String htmlContent) {
    return Container(
      color: Colors.grey[200],
      child: SingleChildScrollView(
        child: AccuratePrintPreviewWidget(
          htmlContent: htmlContent,
          scale: 0.8,
          showPageBorder: true,
          onContentReady: () {
            if (mounted) {
              _addNotification('印刷プレビューの準備が完了しました', SystemMessageType.success);
            }
          },
          onError: (error) {
            if (mounted) {
              _addNotification('印刷プレビューエラー: $error', SystemMessageType.error);
            }
          },
        ),
      ),
    );
  }

  void _generatePdf(BuildContext context) async {
    try {
      await context.read<PreviewProvider>().generatePdf();
      
      // スナックバー表示（上部表示・×ボタン付き）
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ PDFを生成しました'),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
          action: SnackBarAction(
            label: '✕',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      
      // チャット内通知も追加
      final adkChatProvider = context.read<AdkChatProvider>();
      adkChatProvider.addPdfGeneratedMessage('📄 PDFの生成が完了しました！ダウンロードをご確認ください。');
      
      // プレビューエリアの通知も追加
      _addNotification('PDFの生成が完了しました', SystemMessageType.pdfGenerated);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ PDF生成に失敗しました: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
          action: SnackBarAction(
            label: '✕',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      
      // エラーもチャット内に通知
      final adkChatProvider = context.read<AdkChatProvider>();
      adkChatProvider.addErrorMessage('❌ PDF生成に失敗しました: $e');
      
      // プレビューエリアのエラー通知も追加
      _addNotification('PDF生成に失敗しました: $e', SystemMessageType.error);
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
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
          action: SnackBarAction(
            label: '✕',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _regenerateContent(BuildContext context) async {
    final previewProvider = context.read<PreviewProvider>();
    final adkChatProvider = context.read<AdkChatProvider>();

    if (previewProvider.htmlContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('再生成するコンテンツがありません'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
          action: SnackBarAction(
            label: '✕',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      return;
    }

    try {
      // PreviewProviderの再生成処理を開始
      await previewProvider.regenerateContent();

      // 既存コンテンツの要約を取得（PreviewProvider内で解析済み）
      final contentSummary =
          previewProvider.extractContentSummary(previewProvider.htmlContent);

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
        SnackBar(
          content: const Text('🔄 コンテンツの再生成を開始しました...'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
          action: SnackBarAction(
            label: '✕',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 再生成に失敗しました: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
          action: SnackBarAction(
            label: '✕',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _openQuillEditor(BuildContext context) {
    html.window.open('/quill/', '_blank');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('📝 Quillエディタを新しいタブで開きました'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
        action: SnackBarAction(
          label: '✕',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
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

  /// 旧エディター（SimpleHtmlEditor）を表示するダイアログ
  void _showLegacyEditor(BuildContext context, PreviewProvider previewProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(40),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.text_fields, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '旧エディター（テキストベース）',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('閉じる'),
                    ),
                  ],
                ),
              ),
              
              // エディター部分
              Expanded(
                child: SimpleHtmlEditorWidget(
                  initialContent: previewProvider.htmlContent,
                  onContentChanged: (editedHtml) {
                    try {
                      previewProvider.updateHtmlContent(editedHtml);
                      _addNotification('旧エディターで編集内容を更新しました', SystemMessageType.success);
                    } catch (e) {
                      _addNotification('編集内容の保存に失敗: $e', SystemMessageType.error);
                    }
                  },
                  height: 400, // 適切な高さに変更
                ),
              ),
              
              // フッター
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '注意: 旧エディターはHTMLの構造を保持しません。編集後、色やスタイルが失われる可能性があります。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
