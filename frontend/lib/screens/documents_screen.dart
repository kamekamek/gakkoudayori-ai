import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/document_history_service.dart';
import '../models/document.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final DocumentHistoryService _historyService = DocumentHistoryService();
  List<Document> _documents = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, draft, published

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    try {
      final documents = await _historyService.getAllDocuments();
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ドキュメントの読み込みに失敗しました: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  List<Document> get _filteredDocuments {
    var filtered = _documents.where((doc) {
      // 検索フィルター
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!doc.title.toLowerCase().contains(query) &&
            !doc.content.toLowerCase().contains(query)) {
          return false;
        }
      }

      // ステータスフィルター
      switch (_selectedFilter) {
        case 'draft':
          return doc.status == DocumentStatus.draft;
        case 'published':
          return doc.status == DocumentStatus.published;
        default:
          return true;
      }
    }).toList();

    // 更新日時でソート（新しい順）
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ドキュメント一覧'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => context.go('/editor'),
            tooltip: '新規作成',
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索・フィルター
          _buildSearchAndFilter(),

          // ドキュメント一覧
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDocuments.isEmpty
                    ? _buildEmptyState()
                    : _buildDocumentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 検索バー
          TextField(
            decoration: InputDecoration(
              hintText: 'ドキュメントを検索...',
              prefixIcon: const Icon(LucideIcons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.gray300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.gray300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),

          const SizedBox(height: 12),

          // フィルターチップ
          Row(
            children: [
              _buildFilterChip('すべて', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('下書き', 'draft'),
              const SizedBox(width: 8),
              _buildFilterChip('公開済み', 'published'),
              const Spacer(),
              Text(
                '${_filteredDocuments.length}件',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.gray500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryColor.withOpacity(0.1),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.gray600,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : AppTheme.gray300,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.fileText,
            size: 64,
            color: AppTheme.gray400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? '検索結果が見つかりませんでした' : 'まだドキュメントがありません',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.gray500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? '別のキーワードで検索してみてください'
                : '新しいドキュメントを作成しましょう',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray400,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/editor'),
            icon: const Icon(LucideIcons.plus),
            label: const Text('新規作成'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList() {
    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredDocuments.length,
        itemBuilder: (context, index) {
          final document = _filteredDocuments[index];
          return _buildDocumentCard(document);
        },
      ),
    );
  }

  Widget _buildDocumentCard(Document document) {
    final isDraft = document.status == DocumentStatus.draft;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openDocument(document),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ステータスアイコン
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDraft
                      ? AppTheme.warningColor.withOpacity(0.1)
                      : AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isDraft ? LucideIcons.edit : LucideIcons.checkCircle,
                  color:
                      isDraft ? AppTheme.warningColor : AppTheme.successColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // ドキュメント情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusChip(document.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (document.content.isNotEmpty) ...[
                      Text(
                        _stripHtmlTags(document.content),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 14,
                          color: AppTheme.gray500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(document.updatedAt),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.gray500,
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          '${document.content.length}文字',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.gray500,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // アクションメニュー
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical),
                onSelected: (value) => _handleDocumentAction(value, document),
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
                        Icon(LucideIcons.share, size: 16),
                        SizedBox(width: 8),
                        Text('共有'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
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
    );
  }

  Widget _buildStatusChip(DocumentStatus status) {
    final isDraft = status == DocumentStatus.draft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDraft
            ? AppTheme.warningColor.withOpacity(0.1)
            : AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isDraft ? '下書き' : '公開済み',
        style: TextStyle(
          fontSize: 12,
          color: isDraft ? AppTheme.warningColor : AppTheme.successColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _openDocument(Document document) {
    context.go('/editor/${document.id}');
  }

  void _handleDocumentAction(String action, Document document) {
    switch (action) {
      case 'edit':
        _openDocument(document);
        break;
      case 'duplicate':
        _duplicateDocument(document);
        break;
      case 'share':
        _shareDocument(document);
        break;
      case 'delete':
        _deleteDocument(document);
        break;
    }
  }

  Future<void> _duplicateDocument(Document document) async {
    try {
      final newDocument = Document(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${document.title} (コピー)',
        content: document.content,
        status: DocumentStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        thumbnail: document.thumbnail,
      );

      await _historyService.saveDocument(newDocument);
      await _loadDocuments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ドキュメントを複製しました'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('複製に失敗しました: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _shareDocument(Document document) {
    // TODO: 共有機能の実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('共有機能は準備中です')),
    );
  }

  Future<void> _deleteDocument(Document document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ドキュメントを削除'),
        content: Text('「${document.title}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _historyService.deleteDocument(document.id);
        await _loadDocuments();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ドキュメントを削除しました'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('削除に失敗しました: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'たった今';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
    }
  }
}
