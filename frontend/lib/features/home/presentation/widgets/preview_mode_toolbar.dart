import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../editor/providers/preview_provider.dart';
import 'classroom_post_dialog.dart';
import '../../../../services/pdf_api_service.dart';
import '../../../ai_assistant/providers/adk_chat_provider.dart';
import '../../../../core/models/chat_message.dart';

/// プレビューモード切り替えツールバー
class PreviewModeToolbar extends StatelessWidget {
  final PreviewMode currentMode;
  final Function(PreviewMode) onModeChanged;
  final VoidCallback onPdfGenerate;
  final VoidCallback onPrintPreview;
  final VoidCallback onRegenerate;
  final bool canExecuteActions;
  final Function(String, SystemMessageType)? onNotification;

  const PreviewModeToolbar({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.onPdfGenerate,
    required this.onPrintPreview,
    required this.onRegenerate,
    this.canExecuteActions = true,
    this.onNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // プレビューモード切り替えボタン
            _buildModeButton(
              context,
              icon: Icons.visibility,
              label: 'プレビュー',
              mode: PreviewMode.preview,
              isSelected: currentMode == PreviewMode.preview,
            ),

            const SizedBox(width: 6),

            _buildModeButton(
              context,
              icon: Icons.edit,
              label: '編集',
              mode: PreviewMode.edit,
              isSelected: currentMode == PreviewMode.edit,
            ),

            const SizedBox(width: 6),

            _buildModeButton(
              context,
              icon: Icons.print,
              label: '印刷',
              mode: PreviewMode.printView,
              isSelected: currentMode == PreviewMode.printView,
            ),

            const SizedBox(width: 6),

            _buildModeButton(
              context,
              icon: Icons.picture_as_pdf,
              label: 'PDF',
              mode: PreviewMode.edit, // PDFボタンと��て使用
              isSelected: false,
              onTap: onPdfGenerate,
            ),

            const SizedBox(width: 6),

            _buildModeButton(
              context,
              icon: Icons.school,
              label: '📚Classroom',
              mode: PreviewMode.edit, // Classroomボタンとして使用
              isSelected: false,
              onTap: () => _showClassroomDialog(context),
            ),

            const SizedBox(width: 6),

            _buildModeButton(
              context,
              icon: Icons.refresh,
              label: '🔄',
              mode: PreviewMode.edit, // 再生成ボタンとして使用
              isSelected: false,
              onTap: onRegenerate,
            ),

            const SizedBox(width: 16),

            // サンプル読み込みボタン
            _buildActionButton(
              context,
              icon: Icons.article,
              tooltip: 'サンプル読み込み',
              onPressed: () => _loadSampleContent(context),
              color: const Color(0xFFFF6B35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required PreviewMode mode,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(6),
      color: isSelected
          ? const Color(0xFF2c5aa0).withOpacity(0.1)
          : Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap ?? () => onModeChanged(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? const Color(0xFF2c5aa0)
                    : const Color(0xFF616161),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? const Color(0xFF2c5aa0)
                      : const Color(0xFF616161),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: color.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature機能'),
        content: Text('$feature機能は現在開発中です。\n次のアップデートでご利用いただけるようになります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }

  void _loadSampleContent(BuildContext context) {
    context.read<PreviewProvider>().loadSampleContent();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('📄 サンプル学級通信を読み込みました'),
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
    
    // プレビューエリアの通知も追加
    onNotification?.call('サンプル学級通信を読み込みました', SystemMessageType.success);
  }

  void _showClassroomDialog(BuildContext context) async {
    final previewProvider = context.read<PreviewProvider>();

    if (previewProvider.htmlContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ 投稿するコンテンツがありません'),
          backgroundColor: Colors.red,
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
      return;
    }

    try {
      // PDF生成
      final result = await PdfApiService.generatePdf(
        htmlContent: previewProvider.htmlContent,
        title: 'AI学級通信',
      );

      if (result['success'] == true) {
        final pdfBase64 = result['data']['pdf_base64'];
        final pdfBytes = base64Decode(pdfBase64);

        // Classroomダイアログを表示
        final posted = await showDialog<bool>(
          context: context,
          builder: (context) => ClassroomPostDialog(
            pdfBytes: pdfBytes,
            htmlContent: previewProvider.htmlContent,
            title: 'AI学級通信',
          ),
        );

        if (posted == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Classroomに投稿しました'),
              backgroundColor: Colors.green,
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
          adkChatProvider.addClassroomPostedMessage('🎓 Google Classroomへの投稿が完了しました！生徒が確認できます。');
          
          // プレビューエリアの通知も追加
          onNotification?.call('Classroom投稿が完了しました', SystemMessageType.classroomPosted);
        }
      } else {
        throw Exception(result['error'] ?? 'PDF生成に失敗しました');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Classroom投稿の準備に失敗しました: $e'),
          backgroundColor: Colors.red,
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
      adkChatProvider.addErrorMessage('❌ Classroom投稿の準備に失敗しました: $e');
      
      // プレビューエリアのエラー通知も追加
      onNotification?.call('Classroom投稿の準備に失敗しました: $e', SystemMessageType.error);
    }
  }
}
