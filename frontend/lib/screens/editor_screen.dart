import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/voice_input_panel.dart';
import '../widgets/text_editor_panel.dart';
import '../widgets/preview_panel.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

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
        ).animate()
          .scale(
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
          backgroundColor: appState.isRecording ? AppTheme.errorColor : AppTheme.primaryColor,
          foregroundColor: Colors.white,
          icon: Icon(appState.isRecording ? LucideIcons.micOff : LucideIcons.mic),
          label: Text(appState.isRecording ? '録音停止' : '音声録音'),
        ).animate()
          .slideX(
            begin: 1.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
          ),
      ],
    );
  }

  IconData _getSeasonIcon(String season) {
    switch (season) {
      case '春': return Icons.local_florist;
      case '夏': return Icons.wb_sunny;
      case '秋': return Icons.eco;
      case '冬': return Icons.ac_unit;
      default: return Icons.calendar_today;
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テンプレート選択'),
        content: const Text('どのテンプレートを適用しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: テンプレート適用処理
            },
            child: const Text('適用'),
          ),
        ],
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

    // TODO: AI処理の実装
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI全まかせレイアウトを適用しました！'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    });
  }

  void _startRecording(BuildContext context) {
    final appState = context.read<AppState>();
    appState.startRecording();
    
    // TODO: 実際の音声録音処理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('音声録音を開始しました'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
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

  void _exportToPDF() {
    // TODO: PDF生成処理
  }

  void _exportToHTML() {
    // TODO: HTML生成処理
  }

  void _shareToClassroom() {
    // TODO: Google Classroom API連携
  }

  void _saveToDrive() {
    // TODO: Google Drive API連携
  }

  void _sendLineNotification() {
    // TODO: LINE通知API連携
  }
}