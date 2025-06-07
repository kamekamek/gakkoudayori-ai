import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // 🚧 開発用：認証なしでも動作するよう調整
        final user = authProvider.user;

        return Scaffold(
          appBar: AppBar(
            title: const Text('ゆとり職員室'),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.settings),
                onPressed: () => context.go('/settings'),
              ),
              // 🚧 開発用：認証なしでも動作するよう簡略化
              PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Text(
                          user?.displayName?.isNotEmpty == true
                              ? user!.displayName![0].toUpperCase()
                              : user?.email?[0].toUpperCase() ?? 'T', // デフォルト値
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                onSelected: (value) async {
                  if (value == 'logout') {
                    // 認証機能が完成するまでは何もしない
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('認証機能は準備中です')),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        const Icon(LucideIcons.user, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'テストユーザー',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(
                                user?.email ?? 'test@example.com',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(LucideIcons.logOut, size: 16),
                        SizedBox(width: 8),
                        Text('ログアウト（準備中）'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ウェルカムメッセージ
                _buildWelcomeSection(user),
                const SizedBox(height: 32),

                // クイックアクション
                _buildQuickActions(),
                const SizedBox(height: 32),

                // 最近のドキュメント
                _buildRecentDocuments(),
                const SizedBox(height: 32),

                // 統計情報
                _buildStats(),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.go('/editor'),
            icon: const Icon(LucideIcons.plus),
            label: const Text('新規作成'),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(user) {
    final greeting = _getGreeting();
    // 🚧 開発用：認証なしでも動作するよう調整
    final userName =
        user?.displayName ?? user?.email?.split('@')[0] ?? 'テストユーザー';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting、$userName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '今日も素敵な学級通信を作成しましょう！',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'クイックアクション',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              title: '新規作成',
              subtitle: 'ゼロから作成',
              icon: LucideIcons.plus,
              color: AppTheme.primaryColor,
              onTap: () => context.go('/editor'),
            ),
            _buildActionCard(
              title: 'テンプレート',
              subtitle: 'ひな形から作成',
              icon: LucideIcons.layout,
              color: AppTheme.secondaryColor,
              onTap: () {
                // TODO: テンプレート選択画面に遷移
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('テンプレート機能は準備中です')),
                );
              },
            ),
            _buildActionCard(
              title: '音声入力',
              subtitle: '話して作成',
              icon: LucideIcons.mic,
              color: AppTheme.successColor,
              onTap: () {
                context.go('/editor?mode=voice');
              },
            ),
            _buildActionCard(
              title: '設定',
              subtitle: 'アプリ設定',
              icon: LucideIcons.settings,
              color: AppTheme.gray600,
              onTap: () => context.go('/settings'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentDocuments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '最近のドキュメント',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.go('/documents'),
              child: const Text('すべて表示'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // ダミーデータ
        _buildDocumentCard(
          title: '1月の学級だより',
          lastModified: '2時間前',
          preview: '新年あけましておめでとうございます。3学期がスタートしました...',
          status: 'draft',
        ),
        const SizedBox(height: 12),
        _buildDocumentCard(
          title: '冬休みの思い出特集',
          lastModified: '1日前',
          preview: '楽しい冬休みを過ごした子どもたちの様子をお伝えします...',
          status: 'published',
        ),
        const SizedBox(height: 12),
        _buildDocumentCard(
          title: '3学期の目標',
          lastModified: '3日前',
          preview: '一年の締めくくりとなる3学期。みんなで新たな目標を...',
          status: 'draft',
        ),
      ],
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String lastModified,
    required String preview,
    required String status,
  }) {
    final isDraft = status == 'draft';

    return Card(
      child: InkWell(
        onTap: () {
          // TODO: エディタ画面に遷移
          context.go('/editor/sample-id');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                              color: isDraft
                                  ? AppTheme.warningColor
                                  : AppTheme.successColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '最終更新: $lastModified',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.gray500,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: AppTheme.gray400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '統計情報',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: '総ドキュメント数',
                value: '12',
                icon: LucideIcons.fileText,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: '今月の作成数',
                value: '3',
                icon: LucideIcons.trendingUp,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: '下書き',
                value: '2',
                icon: LucideIcons.edit,
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: '公開済み',
                value: '10',
                icon: LucideIcons.checkCircle,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'おはようございます';
    } else if (hour < 18) {
      return 'こんにちは';
    } else {
      return 'こんばんは';
    }
  }
}
