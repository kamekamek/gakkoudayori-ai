import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../editor/providers/preview_provider.dart';
import 'classroom_post_dialog.dart';
import '../../../../services/pdf_api_service.dart';

/// プレビューモード切り替えツールバー
class PreviewModeToolbar extends StatelessWidget {
  final PreviewMode currentMode;
  final Function(PreviewMode) onModeChanged;
  final VoidCallback onPdfGenerate;
  final VoidCallback onPrintPreview;
  final VoidCallback onRegenerate;
  final bool canExecuteActions;

  const PreviewModeToolbar({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.onPdfGenerate,
    required this.onPrintPreview,
    required this.onRegenerate,
    this.canExecuteActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // プレビューモード切り替えボタン
          _buildModeButton(
            context,
            icon: Icons.preview,
            label: 'プレビュー',
            mode: PreviewMode.preview,
            isSelected: currentMode == PreviewMode.preview,
          ),
          
          const SizedBox(width: 8),
          
          _buildModeButton(
            context,
            icon: Icons.edit,
            label: '編集',
            mode: PreviewMode.edit,
            isSelected: currentMode == PreviewMode.edit,
          ),
          
          const SizedBox(width: 8),
          
          _buildModeButton(
            context,
            icon: Icons.print,
            label: '印刷ビュー',
            mode: PreviewMode.printView,
            isSelected: currentMode == PreviewMode.printView,
          ),
          
          const Spacer(),
          
          // サンプル読み込みボタン（常に表示）
          _buildActionButton(
            context,
            icon: Icons.article,
            tooltip: 'サンプル読み込み',
            onPressed: () => _loadSampleContent(context),
            color: Colors.orange,
          ),
          
          const SizedBox(width: 8),
          
          // アクションボタン群
          if (canExecuteActions) ...[
            // PDF生成ボタン
            _buildActionButton(
              context,
              icon: Icons.picture_as_pdf,
              tooltip: 'PDF出力',
              onPressed: onPdfGenerate,
              color: Colors.purple,
            ),
            
            const SizedBox(width: 8),
            
            // Classroom投稿ボタン
            _buildActionButton(
              context,
              icon: Icons.school,
              tooltip: 'Classroom投稿',
              onPressed: () => _showClassroomDialog(context),
              color: Colors.green,
            ),
            
            const SizedBox(width: 8),
            
            // 再生成ボタン
            _buildActionButton(
              context,
              icon: Icons.refresh,
              tooltip: '再生成',
              onPressed: onRegenerate,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required PreviewMode mode,
    required bool isSelected,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onModeChanged(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
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
      const SnackBar(
        content: Text('📄 サンプル学級通信を読み込みました'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showClassroomDialog(BuildContext context) async {
    final previewProvider = context.read<PreviewProvider>();
    
    if (previewProvider.htmlContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 投稿するコンテンツがありません'),
          backgroundColor: Colors.red,
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
            const SnackBar(
              content: Text('✅ Classroomに投稿しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['error'] ?? 'PDF生成に失敗しました');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Classroom投稿の準備に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}