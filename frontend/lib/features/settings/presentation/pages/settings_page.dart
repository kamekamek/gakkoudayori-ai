import 'package:flutter/material.dart';

/// 設定画面
/// アプリケーションの各種設定を管理するページ
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 設定項目のグループ
  final List<SettingGroup> _settingGroups = [
    SettingGroup(
      title: 'アカウント設定',
      icon: Icons.person,
      settings: [
        SettingItem(
          title: 'プロフィール編集',
          subtitle: 'ユーザー情報を変更します',
          icon: Icons.edit,
          onTap: (context) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('プロフィール編集機能は開発中です')),
            );
          },
        ),
        SettingItem(
          title: 'パスワード変更',
          subtitle: 'セキュリティを強化します',
          icon: Icons.lock,
          onTap: (context) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('パスワード変更機能は開発中です')),
            );
          },
        ),
      ],
    ),
    SettingGroup(
      title: 'アプリケーション設定',
      icon: Icons.settings,
      settings: [
        SettingItem(
          title: 'テーマ設定',
          subtitle: '表示テーマをカスタマイズします',
          icon: Icons.color_lens,
          onTap: (context) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('テーマ設定機能は開発中です')),
            );
          },
        ),
        SettingItem(
          title: '通知設定',
          subtitle: '通知の種類と頻度を設定します',
          icon: Icons.notifications,
          onTap: (context) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('通知設定機能は開発中です')),
            );
          },
        ),
        SettingItem(
          title: '言語設定',
          subtitle: 'アプリの表示言語を選択します',
          icon: Icons.language,
          onTap: (context) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('言語設定機能は開発中です')),
            );
          },
        ),
      ],
    ),
    SettingGroup(
      title: 'アクセシビリティ',
      icon: Icons.accessibility,
      settings: [
        SettingItem(
          title: 'フォントサイズ',
          subtitle: '文字の大きさを調整します',
          icon: Icons.format_size,
          onTap: (context) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('フォントサイズ設定機能は開発中です')),
            );
          },
        ),
        SettingItem(
          title: 'コントラスト設定',
          subtitle: '画面の見やすさを調整します',
          icon: Icons.contrast,
          onTap: (context) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('コントラスト設定機能は開発中です')),
            );
          },
        ),
      ],
    ),
    SettingGroup(
      title: 'ヘルプとサポート',
      icon: Icons.help,
      settings: [
        SettingItem(
          title: 'ユーザーガイド',
          subtitle: 'アプリの使い方を学びます',
          icon: Icons.menu_book,
          onTap: (context) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ユーザーガイド機能は開発中です')),
            );
          },
        ),
        SettingItem(
          title: 'お問い合わせ',
          subtitle: 'サポートチームに連絡します',
          icon: Icons.support_agent,
          onTap: (context) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('お問い合わせ機能は開発中です')),
            );
          },
        ),
        SettingItem(
          title: 'アプリについて',
          subtitle: 'バージョン情報やライセンス',
          icon: Icons.info,
          onTap: (context) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('アプリ情報機能は開発中です')),
            );
          },
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _settingGroups.length,
        itemBuilder: (context, index) {
          final group = _settingGroups[index];
          return _buildSettingGroup(group);
        },
      ),
    );
  }

  Widget _buildSettingGroup(SettingGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(group.icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                group.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        ...group.settings.map((setting) => _buildSettingItem(setting)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSettingItem(SettingItem setting) {
    return ListTile(
      leading: Icon(setting.icon),
      title: Text(setting.title),
      subtitle: Text(setting.subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => setting.onTap(context),
    );
  }
}

/// 設定グループのモデル
class SettingGroup {
  final String title;
  final IconData icon;
  final List<SettingItem> settings;

  SettingGroup({
    required this.title,
    required this.icon,
    required this.settings,
  });
}

/// 設定項目のモデル
class SettingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Function(BuildContext) onTap;

  SettingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}
