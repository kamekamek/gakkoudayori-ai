import 'package:flutter/material.dart';
import 'package:yutori_kyoshitu/features/layout/presentation/widgets/app_shell.dart';
import 'package:yutori_kyoshitu/features/home/presentation/pages/home_page.dart';
import 'package:yutori_kyoshitu/features/settings/presentation/pages/settings_page.dart';

/// メインレイアウトページ
/// アプリケーションの基本3カラムレイアウトを提供します
class MainLayoutPage extends StatefulWidget {
  const MainLayoutPage({super.key});

  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage> {
  int _selectedIndex = 0;

  // ナビゲーションメニュー項目
  final List<NavigationItem> _navItems = [
    NavigationItem(
      title: 'ホーム',
      icon: Icons.home,
      page: const HomePage(),
    ),
    NavigationItem(
      title: '下書き',
      icon: Icons.edit_document,
      page: const Center(child: Text('下書き一覧')),
    ),
    NavigationItem(
      title: 'テンプレート',
      icon: Icons.article,
      page: const Center(child: Text('テンプレート一覧')),
    ),
    NavigationItem(
      title: '設定',
      icon: Icons.settings,
      page: const SettingsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navigationColumn: _buildNavigationColumn(),
      centerColumn: _navItems[_selectedIndex].page,
      previewColumn: _buildPreviewColumn(),
    );
  }

  /// ナビゲーション列を構築
  Widget _buildNavigationColumn() {
    return Column(
      children: [
        // ヘッダー
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '学校だよりAI',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text('教師のためのAI通信作成ツール'),
            ],
          ),
        ),

        // メニュー項目
        Expanded(
          child: ListView.builder(
            itemCount: _navItems.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Icon(_navItems[index].icon),
                title: Text(_navItems[index].title),
                selected: _selectedIndex == index,
                onTap: () => setState(() => _selectedIndex = index),
              );
            },
          ),
        ),

        // 新規作成ボタン
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('新規作成機能は開発中です')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('新規作成'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ],
    );
  }

  /// プレビュー列を構築
  Widget _buildPreviewColumn() {
    return Column(
      children: [
        // プレビューヘッダー
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.desktop_windows,
                  color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text('デスクトップビュー', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        const Divider(),

        // プレビューモード切替タブ
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.desktop_windows),
                label: const Text('PC'),
                style: TextButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.smartphone),
                label: const Text('モバイル'),
              ),
            ),
          ],
        ),

        // プレビューコンテンツ
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Center(
                child: Text('プレビューコンテンツがここに表示されます'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ナビゲーション項目データモデル
class NavigationItem {
  final String title;
  final IconData icon;
  final Widget page;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.page,
  });
}
