import 'package:flutter/material.dart';
import '../../../editor/providers/preview_provider.dart';

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
            
            // Classroom投稿ボタン（将来実装）
            _buildActionButton(
              context,
              icon: Icons.school,
              tooltip: 'Classroom投稿',
              onPressed: () => _showComingSoonDialog(context, 'Classroom投稿'),
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
}