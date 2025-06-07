import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/season_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/recent_documents_list.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ゆとり職員室'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildWelcomeSection(context),
                const SizedBox(height: 24),
                _buildSeasonSelector(context),
                const SizedBox(height: 24),
                Text(
                  'クイックアクション',
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate().fadeIn(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 600),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                QuickActionButton(
                  icon: LucideIcons.mic,
                  title: '音声で作成',
                  subtitle: 'ワンタップ録音',
                  color: AppTheme.primaryColor,
                  onTap: () => _startVoiceRecording(context),
                ).animate().fadeIn(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 600),
                ),
                QuickActionButton(
                  icon: LucideIcons.edit,
                  title: '文字で作成',
                  subtitle: 'テキスト入力',
                  color: AppTheme.secondaryColor,
                  onTap: () => context.push('/editor'),
                ).animate().fadeIn(
                  delay: const Duration(milliseconds: 300),
                  duration: const Duration(milliseconds: 600),
                ),
                QuickActionButton(
                  icon: LucideIcons.image,
                  title: 'テンプレート',
                  subtitle: 'デザイン選択',
                  color: AppTheme.accentColor,
                  onTap: () => _showTemplateSelector(context),
                ).animate().fadeIn(
                  delay: const Duration(milliseconds: 400),
                  duration: const Duration(milliseconds: 600),
                ),
                QuickActionButton(
                  icon: LucideIcons.history,
                  title: '履歴から複製',
                  subtitle: '過去の通信',
                  color: Colors.purple,
                  onTap: () => _showDocumentHistory(context),
                ).animate().fadeIn(
                  delay: const Duration(milliseconds: 500),
                  duration: const Duration(milliseconds: 600),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _buildRecentDocuments(context),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/editor'),
        icon: const Icon(LucideIcons.plus),
        label: const Text('新しい学級通信'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ).animate().slideX(
        begin: 1.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final appState = context.watch<AppState>();
    final now = DateTime.now();
    final timeOfDay = now.hour < 12 
        ? 'おはようございます' 
        : now.hour < 18 
            ? 'お疲れさまです' 
            : 'お疲れさまでした';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.sun,
                  size: 32,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeOfDay,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '今日も子どもたちのために、素敵な学級通信を作りましょう',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '現在のテーマ: ${appState.currentSeasonName}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 600),
    ).slideY(
      begin: -0.2,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutQuart,
    );
  }



  Widget _buildSeasonSelector(BuildContext context) {
    final appState = context.watch<AppState>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '季節テーマ',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SeasonCard(
                seasonName: '春',
                colors: AppTheme.springColors,
                isSelected: appState.currentSeasonIndex == 0,
                onTap: () => appState.setSeason(0),
              ),
              const SizedBox(width: 12),
              SeasonCard(
                seasonName: '夏',
                colors: AppTheme.summerColors,
                isSelected: appState.currentSeasonIndex == 1,
                onTap: () => appState.setSeason(1),
              ),
              const SizedBox(width: 12),
              SeasonCard(
                seasonName: '秋',
                colors: AppTheme.autumnColors,
                isSelected: appState.currentSeasonIndex == 2,
                onTap: () => appState.setSeason(2),
              ),
              const SizedBox(width: 12),
              SeasonCard(
                seasonName: '冬',
                colors: AppTheme.winterColors,
                isSelected: appState.currentSeasonIndex == 3,
                onTap: () => appState.setSeason(3),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 400),
      duration: const Duration(milliseconds: 600),
    );
  }

  Widget _buildRecentDocuments(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '最近の学級通信',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextButton(
              onPressed: () => _showAllDocuments(context),
              child: const Text('すべて見る'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const RecentDocumentsList(),
      ],
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 600),
      duration: const Duration(milliseconds: 600),
    );
  }

  void _startVoiceRecording(BuildContext context) async {
    final appState = context.read<AppState>();

    // マイク権限チェック
    if (!await appState.ensureMicPermission()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('マイク権限が必要です'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    appState.startRecording();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          appState.stopRecording();
          return true;
        },
        child: AlertDialog(
          title: const Text('音声録音中'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.mic,
                size: 48,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              const Text('録音中です...'),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                appState.stopRecording();
                Navigator.of(context).pop();
                context.push('/editor');
              },
              child: const Text('停止'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'テンプレートを選択',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) => Card(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/editor');
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.springColors[index % 3],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    LucideIcons.fileText,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'テンプレート ${index + 1}',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocumentHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(LucideIcons.history, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      '学級通信履歴',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Consumer<AppState>(
                    builder: (context, appState, child) {
                      if (appState.recentDocuments.isEmpty) {
                        return const Center(
                          child: Text('まだ学級通信がありません'),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: appState.recentDocuments.length,
                        itemBuilder: (context, index) {
                          final document = appState.recentDocuments[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                child: Text(
                                  document.thumbnail,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              title: Text(document.title),
                              subtitle: Text(document.formattedDate),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // 複製して新しいドキュメントとして開く
                                  final duplicatedDocument = Document(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    title: '${document.title}のコピー',
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                    thumbnail: document.thumbnail,
                                    status: DocumentStatus.draft,
                                    content: document.content,
                                    views: 0,
                                  );
                                  context.push('/editor', extra: {'document': duplicatedDocument});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                child: const Text('複製'),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllDocuments(BuildContext context) {
    // 履歴画面と同じ機能を使用（将来的にはページネーションなど追加）
    _showDocumentHistory(context);
  }
}