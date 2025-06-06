import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/app_state.dart';
import '../models/document.dart';
import '../theme/app_theme.dart';

class RecentDocumentsList extends StatefulWidget {
  const RecentDocumentsList({super.key});

  @override
  State<RecentDocumentsList> createState() => _RecentDocumentsListState();
}

class _RecentDocumentsListState extends State<RecentDocumentsList> {
  @override
  void initState() {
    super.initState();
    // ウィジェット初期化時に文書データを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadRecentDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // ローディング中の表示
    if (appState.isLoadingDocuments) {
      return _buildLoadingState();
    }

    // 文書データをAppStateから取得
    final documents = appState.recentDocuments;

    if (documents.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: documents.asMap().entries.map((entry) {
        final index = entry.key;
        final document = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildDocumentCard(context, document, index),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '文書を読み込み中...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              LucideIcons.fileText,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '学級通信がまだありません',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '最初の学級通信を作成してみましょう',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 600)).scale(
          begin: const Offset(0.8, 0.8),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildDocumentCard(
      BuildContext context, Document document, int index) {
    final isRecent = index == 0;

    return Card(
      elevation: isRecent ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRecent
            ? BorderSide(
                color: AppTheme.primaryColor.withOpacity(0.3), width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _openDocument(context, document),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // サムネイル
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getStatusColor(document.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    document.thumbnail,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: isRecent
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isRecent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '最新',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          document.formattedDate,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(document.status),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            document.statusText,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // アクションボタン
              PopupMenuButton<String>(
                icon: Icon(
                  LucideIcons.moreVertical,
                  color: Colors.grey[600],
                  size: 20,
                ),
                onSelected: (value) => _handleAction(context, value, document),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(LucideIcons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('編集'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(LucideIcons.copy, size: 16),
                        SizedBox(width: 8),
                        Text('複製'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(LucideIcons.share2, size: 16),
                        SizedBox(width: 8),
                        Text('共有'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('削除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideX(
          begin: 0.3,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuart,
        );
  }

  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.published:
        return AppTheme.successColor;
      case DocumentStatus.draft:
        return AppTheme.secondaryColor;
      case DocumentStatus.scheduled:
        return AppTheme.primaryColor;
      case DocumentStatus.archived:
        return Colors.grey;
      case DocumentStatus.inReview:
        return AppTheme.accentColor;
    }
  }

  void _openDocument(BuildContext context, Document document) {
    // TODO: ドキュメント編集画面へ遷移
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「${document.title}」を開きます'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _handleAction(BuildContext context, String action, Document document) {
    switch (action) {
      case 'edit':
        // TODO: 編集機能の実装
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${document.title}」を編集します'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        break;
      case 'duplicate':
        // TODO: 複製機能の実装
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('複製機能は開発中です'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
        break;
      case 'share':
        // TODO: 共有機能の実装
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('共有機能は開発中です'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(context, document);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context, Document document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('「${document.title}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // AppStateから削除
              context.read<AppState>().removeRecentDocument(document.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('「${document.title}」を削除しました'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
