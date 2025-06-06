import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/voice_input_panel.dart';
import '../models/template.dart';
import '../widgets/text_editor_panel.dart';
import '../widgets/preview_panel.dart';

class EditorScreen extends StatefulWidget {
  final String? documentId;

  const EditorScreen({super.key, this.documentId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // documentIdが指定されている場合はドキュメントを読み込み
    if (widget.documentId != null) {
      _loadDocument(widget.documentId!);
    }
  }

  void _loadDocument(String documentId) {
    // TODO: 実際のドキュメント読み込み処理を実装
    // 現在はプレースホルダー
    debugPrint('Loading document: $documentId');
    // Future implementation: Firestore からドキュメントを読み込み
    // final appState = context.read<AppState>();
    // appState.loadDocument(documentId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 1024;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: isWideScreen ? _buildDesktopLayout() : _buildMobileLayout(),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final appState = context.watch<AppState>();

    return AppBar(
      title: const Text('学級通信エディタ'),
      actions: [
        // 季節テーマ表示
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getSeasonIcon(appState.currentSeasonName),
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                appState.currentSeasonName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),

        // プレビューモード切り替え
        IconButton(
          icon: Icon(_isPreviewMode ? LucideIcons.edit : LucideIcons.eye),
          onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
          tooltip: _isPreviewMode ? '編集モード' : 'プレビューモード',
        ),

        // 保存ボタン
        IconButton(
          icon: const Icon(LucideIcons.save),
          onPressed: () => _saveDocument(context),
          tooltip: '保存',
        ),

        // メニューボタン
        PopupMenuButton<String>(
          icon: const Icon(LucideIcons.moreVertical),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'template',
              child: Row(
                children: [
                  Icon(LucideIcons.layout, size: 16),
                  SizedBox(width: 8),
                  Text('テンプレート'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(LucideIcons.download, size: 16),
                  SizedBox(width: 8),
                  Text('エクスポート'),
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
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    // プレビューモードの場合はプレビューのみ表示
    if (_isPreviewMode) {
      return const PreviewPanel();
    }

    return Row(
      children: [
        // 左パネル: 音声入力
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: const VoiceInputPanel(),
          ),
        ),

        // 中央パネル: エディタ
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: const TextEditorPanel(),
          ),
        ),

        // 右パネル: プレビュー
        Expanded(
          flex: 3,
          child: const PreviewPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    if (_isPreviewMode) {
      return const PreviewPanel();
    }

    return Column(
      children: [
        // タブバー
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey[600],
            tabs: const [
              Tab(
                icon: Icon(LucideIcons.mic),
                text: '音声入力',
              ),
              Tab(
                icon: Icon(LucideIcons.edit),
                text: 'エディタ',
              ),
              Tab(
                icon: Icon(LucideIcons.eye),
                text: 'プレビュー',
              ),
            ],
          ),
        ),

        // タブビュー
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              VoiceInputPanel(),
              TextEditorPanel(),
              PreviewPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final appState = context.watch<AppState>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AI全まかせボタン
        FloatingActionButton(
          heroTag: 'ai_auto',
          onPressed: () => _triggerAIAutoLayout(context),
          backgroundColor: AppTheme.accentColor,
          foregroundColor: Colors.white,
          child: const Icon(LucideIcons.sparkles),
        ).animate().scale(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
            ),

        const SizedBox(height: 16),

        // 音声録音ボタン
        FloatingActionButton.extended(
          heroTag: 'voice_record',
          onPressed: appState.isRecording
              ? () => _stopRecording(context)
              : () => _startRecording(context),
          backgroundColor: appState.isRecording
              ? AppTheme.errorColor
              : AppTheme.primaryColor,
          foregroundColor: Colors.white,
          icon:
              Icon(appState.isRecording ? LucideIcons.micOff : LucideIcons.mic),
          label: Text(appState.isRecording ? '録音停止' : '音声録音'),
        ).animate().slideX(
              begin: 1.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
            ),
      ],
    );
  }

  IconData _getSeasonIcon(String season) {
    switch (season) {
      case '春':
        return Icons.local_florist;
      case '夏':
        return Icons.wb_sunny;
      case '秋':
        return Icons.eco;
      case '冬':
        return Icons.ac_unit;
      default:
        return Icons.calendar_today;
    }
  }

  void _saveDocument(BuildContext context) {
    // TODO: ドキュメント保存処理の実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('学級通信を保存しました'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'template':
        _showTemplateDialog(context);
        break;
      case 'export':
        _showExportDialog(context);
        break;
      case 'share':
        _showShareDialog(context);
        break;
    }
  }

  void _showTemplateDialog(BuildContext context) {
    final templates = Template.getPredefinedTemplates();
    Template? selectedTemplate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('テンプレート選択'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '使用したいテンプレートを選択してください',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      final isSelected = selectedTemplate?.id == template.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: isSelected ? 3 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: isSelected
                              ? BorderSide(
                                  color: AppTheme.primaryColor, width: 2)
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppTheme.primaryColor.withOpacity(0.1),
                            child: Text(
                              template.thumbnail,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(
                            template.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(template.description),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondaryColor
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      template.category,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  LucideIcons.check,
                                  color: AppTheme.primaryColor,
                                )
                              : const Icon(LucideIcons.chevronRight),
                          onTap: () {
                            setDialogState(() {
                              selectedTemplate = template;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (selectedTemplate != null) ...[
                  const Divider(),
                  Text(
                    'プレビュー',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 100,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        selectedTemplate!.content,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 6,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: selectedTemplate != null
                  ? () {
                      Navigator.of(context).pop();
                      _applyTemplate(selectedTemplate!);
                    }
                  : null,
              child: const Text('適用'),
            ),
          ],
        ),
      ),
    );
  }

  void _applyTemplate(Template template) {
    // TODO: 実際のエディタにテンプレート内容を挿入する処理
    // 現在はスナックバーで確認
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「${template.name}」テンプレートを適用しました'),
        backgroundColor: AppTheme.primaryColor,
        action: SnackBarAction(
          label: '元に戻す',
          textColor: Colors.white,
          onPressed: () {
            // TODO: 元に戻す処理
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('テンプレートの適用を取り消しました'),
                backgroundColor: AppTheme.secondaryColor,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エクスポート'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.fileText),
              title: const Text('PDF形式'),
              subtitle: const Text('印刷用のPDFファイル'),
              onTap: () {
                Navigator.of(context).pop();
                _exportToPDF();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.globe),
              title: const Text('HTML形式'),
              subtitle: const Text('Web表示用のHTMLファイル'),
              onTap: () {
                Navigator.of(context).pop();
                _exportToHTML();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('共有'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.mail),
              title: const Text('Google Classroom'),
              subtitle: const Text('クラスに投稿'),
              onTap: () {
                Navigator.of(context).pop();
                _shareToClassroom();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.folderOpen),
              title: const Text('Google Drive'),
              subtitle: const Text('Driveに保存'),
              onTap: () {
                Navigator.of(context).pop();
                _saveToDrive();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.messageCircle),
              title: const Text('LINE通知'),
              subtitle: const Text('保護者に通知'),
              onTap: () {
                Navigator.of(context).pop();
                _sendLineNotification();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _triggerAIAutoLayout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.sparkles, color: AppTheme.accentColor),
            SizedBox(width: 8),
            Text('AI全まかせ機能'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.accentColor),
            SizedBox(height: 16),
            Text('AIが最適なレイアウトを作成しています...'),
          ],
        ),
      ),
    );

    // Call actual AI processing
    _processAILayout().then((_) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI全まかせレイアウトを適用しました！'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }).catchError((error) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $error'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    });
  }

  Future<void> _processAILayout() async {
    // TODO: Implement actual AI processing
    // This should call your AI service
    await Future.delayed(const Duration(seconds: 1)); // Placeholder
  }

  void _startRecording(BuildContext context) {
    final appState = context.read<AppState>();

    try {
      // TODO: Initialize recording service
      // await _recordingService.start();

      appState.startRecording();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('音声録音を開始しました'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('録音の開始に失敗しました: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _stopRecording(BuildContext context) {
    final appState = context.read<AppState>();
    appState.stopRecording();

    // TODO: 録音停止・音声認識処理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('音声録音を停止しました'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  void _exportToPDF() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('PDF生成中...'),
          ],
        ),
        content: Text('HTMLコンテンツからPDFを生成しています。しばらくお待ちください。'),
      ),
    );

    try {
      // TODO: APIサービス統合でPDF生成APIを呼び出し
      // final result = await apiService.generatePdf(htmlContent, options);

      await Future.delayed(const Duration(seconds: 2)); // 仮の処理時間

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDFが正常に生成されました'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ PDF生成に失敗しました: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _exportToHTML() {
    // HTMLエクスポート処理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 HTMLファイルとしてエクスポートしました'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _shareToClassroom() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Classroom に投稿'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('学級通信をClassroomに投稿しますか？'),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(value: true, onChanged: (value) {}),
                const Text('PDF添付'),
              ],
            ),
            Row(
              children: [
                Checkbox(value: false, onChanged: (value) {}),
                const Text('生徒に通知'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  title: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Classroom投稿中...'),
                    ],
                  ),
                ),
              );

              try {
                await Future.delayed(const Duration(seconds: 3)); // 仮の処理時間

                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📚 Google Classroomに正常に投稿されました'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Classroom投稿に失敗しました: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('投稿'),
          ),
        ],
      ),
    );
  }

  void _saveToDrive() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Google Drive保存中...'),
          ],
        ),
      ),
    );

    try {
      await Future.delayed(const Duration(seconds: 2)); // 仮の処理時間

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💾 Google Driveに正常に保存されました'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Drive保存に失敗しました: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _sendLineNotification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LINE通知送信'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('保護者にLINE通知を送信しますか？'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📱 通知内容プレビュー',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                      '🏫 新しい学級通信が配信されました\n📝 今日のお知らせ\n👆 詳細はClassroomでご確認ください'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📱 LINE通知を送信しました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('送信'),
          ),
        ],
      ),
    );
  }
}
