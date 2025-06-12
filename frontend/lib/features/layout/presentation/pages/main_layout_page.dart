import 'package:flutter/material.dart';
import 'package:yutori_kyoshitu/features/layout/presentation/widgets/app_shell.dart';
import 'package:yutori_kyoshitu/features/home/presentation/pages/home_page.dart';
import 'package:yutori_kyoshitu/features/settings/presentation/pages/settings_page.dart';
import 'package:yutori_kyoshitu/features/editor/presentation/pages/editor_page.dart';

/// メインレイアウトページ
/// 統合ナビゲーション設計に基づくレスポンシブレイアウトを提供します
class MainLayoutPage extends StatefulWidget {
  const MainLayoutPage({super.key});

  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage> {
  // ナビゲーションメニュー項目（統合設計）
  final List<NavigationItem> _navItems = [
    NavigationItem(
      title: 'ホーム',
      icon: Icons.home,
      page: const HomePage(),
      tooltip: 'ホーム画面',
      showInMobile: true,
    ),
    NavigationItem(
      title: 'エディタ',
      icon: Icons.edit,
      page: const EditorPage(),
      tooltip: '新規通信作成',
      showInMobile: true,
    ),
    NavigationItem(
      title: '下書き',
      icon: Icons.drafts,
      page: const Center(child: Text('下書き一覧')),
      tooltip: '保存済み下書き',
      showInMobile: true,
    ),
    NavigationItem(
      title: 'テンプレート',
      icon: Icons.article,
      page: const Center(child: Text('テンプレート一覧')),
      tooltip: '通信テンプレート',
      showInMobile: false, // モバイルでは非表示
    ),
    NavigationItem(
      title: '設定',
      icon: Icons.settings,
      page: const SettingsPage(),
      tooltip: 'アプリ設定',
      showInMobile: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      navigationItems: _navItems,
      previewColumn: _buildPreviewColumn(),
      showVoiceInput: true,
      onVoiceInputPressed: _handleVoiceInput,
    );
  }

  /// 音声入力ボタンがタップされた時の処理
  void _handleVoiceInput() {
    // エディタページに切り替え
    final editorIndex = _navItems.indexWhere((item) => item.title == 'エディタ');
    if (editorIndex != -1) {
      // AppShellが内部的に選択状態を管理するため、
      // ここでは音声入力の初期化のみ行う
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('音声入力機能を起動しています...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
