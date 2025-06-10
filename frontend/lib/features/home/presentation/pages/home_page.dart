import 'package:flutter/material.dart';

/// ホーム画面
/// アプリのメインページとして機能する
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // 画面の一覧
  final List<Widget> _pages = [
    const _DashboardTab(),
    const _EditorTab(),
    const _TemplatesTab(),
    const _SettingsTab(),
  ];

  // 下部ナビゲーションバーのアイテム
  final List<BottomNavigationBarItem> _navigationItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'ダッシュボード',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.edit_document),
      label: 'エディタ',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.article),
      label: 'テンプレート',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: '設定',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学校だよりAI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // プロフィール画面への遷移処理
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('プロフィール機能は開発中です')),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: _navigationItems,
      ),
    );
  }
}

/// ダッシュボードタブ
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dashboard, size: 64),
          const SizedBox(height: 16),
          const Text(
            'ダッシュボード',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('最近の活動や統計情報がここに表示されます'),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // 新規作成画面への遷移処理
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('新規作成機能は開発中です')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('新規作成'),
          ),
        ],
      ),
    );
  }
}

/// エディタタブ
class _EditorTab extends StatelessWidget {
  const _EditorTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit_document, size: 64),
          const SizedBox(height: 16),
          const Text(
            'エディタ',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('学級通信の編集を行います'),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // 音声入力画面への遷移処理
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('音声入力機能は開発中です')),
              );
            },
            icon: const Icon(Icons.mic),
            label: const Text('音声入力'),
          ),
        ],
      ),
    );
  }
}

/// テンプレートタブ
class _TemplatesTab extends StatelessWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.article, size: 64),
          const SizedBox(height: 16),
          const Text(
            'テンプレート',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('利用可能なテンプレート一覧'),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // テンプレート作成画面への遷移処理
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('テンプレート作成機能は開発中です')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('テンプレート作成'),
          ),
        ],
      ),
    );
  }
}

/// 設定タブ
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(
          title: Text('設定',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          subtitle: Text('アプリケーション設定を管理します'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('アカウント設定'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('アカウント設定は開発中です')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.color_lens),
          title: const Text('テーマ設定'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('テーマ設定は開発中です')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('通知設定'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('通知設定は開発中です')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('ヘルプとサポート'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ヘルプ機能は開発中です')),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('アプリについて'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: '学校だよりAI',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.school),
              applicationLegalese: '© 2025 学校だよりAI Project',
            );
          },
        ),
      ],
    );
  }
}
