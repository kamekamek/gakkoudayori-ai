import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../home/providers/newsletter_provider.dart';
import '../../../../widgets/user_dictionary_widget.dart';

/// 設定画面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _schoolNameController = TextEditingController();
  final _classNameController = TextEditingController();
  final _teacherNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSettings();
    });
  }

  void _loadCurrentSettings() {
    final provider = context.read<NewsletterProvider>();
    _schoolNameController.text = provider.schoolName;
    _classNameController.text = provider.className;
    _teacherNameController.text = provider.teacherName;
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _classNameController.dispose();
    _teacherNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 基本設定セクション
            _buildSectionCard(
              title: '基本設定',
              icon: Icons.person,
              children: [
                _buildTextField(
                  controller: _schoolNameController,
                  label: '学校名',
                  hint: '例: 〇〇小学校',
                  icon: Icons.school,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _classNameController,
                  label: 'クラス名',
                  hint: '例: 1年1組',
                  icon: Icons.class_,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _teacherNameController,
                  label: '先生のお名前',
                  hint: '例: 田中太郎',
                  icon: Icons.person,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('設定を保存'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ユーザー辞書セクション
            _buildSectionCard(
              title: 'ユーザー辞書',
              icon: Icons.book,
              children: [
                Text(
                  'よく使う言葉を登録して音声認識の精度を上げます',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _openUserDictionary,
                  icon: const Icon(Icons.edit),
                  label: const Text('辞書管理を開く'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ヘルプセクション
            _buildSectionCard(
              title: 'ヘルプ',
              icon: Icons.help,
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('使い方ガイド'),
                  subtitle: const Text('学校だよりAIの使い方を確認'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _showUserGuide,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.quiz),
                  title: const Text('よくある質問'),
                  subtitle: const Text('FAQ・トラブルシューティング'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _showFAQ,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('バージョン情報'),
                  subtitle: const Text('アプリのバージョンと更新情報'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _showVersionInfo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _saveSettings() {
    final provider = context.read<NewsletterProvider>();
    provider.updateSchoolInfo(
      schoolName: _schoolNameController.text.trim(),
      className: _classNameController.text.trim(),
      teacherName: _teacherNameController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 設定を保存しました'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openUserDictionary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserDictionaryWidget(
          userId: 'demo-user', // デモ用のユーザーID。実際の実装ではFirebase Authから取得
          onDictionaryUpdated: () {
            // 辞書更新時の処理（必要に応じて）
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ユーザー辞書が更新されました'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showUserGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使い方ガイド'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. チャットでAIと会話',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('AIと会話しながら学級通信の内容を決めていきます。'),
              SizedBox(height: 12),
              Text(
                '2. リアルタイムプレビュー',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('会話内容に基づいて学級通信が自動生成されます。'),
              SizedBox(height: 12),
              Text(
                '3. 編集・出力',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('プレビューを確認して、編集・PDF出力できます。'),
              SizedBox(height: 12),
              Text(
                '4. 音声入力',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('マイクボタンで音声入力も利用できます。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showFAQ() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('よくある質問'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Q: 音声認識がうまく動作しません',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('A: マイクのアクセス許可を確認してください。また、静かな環境での利用をお勧めします。'),
              SizedBox(height: 12),
              Text(
                'Q: 学級通信が生成されません',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('A: インターネット接続を確認してください。AIサービスにアクセスできない可能性があります。'),
              SizedBox(height: 12),
              Text(
                'Q: データは保存されますか？',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('A: 現在はセッション中のみデータが保持されます。ブラウザを閉じると削除されます。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('バージョン情報'),
        content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('学校だよりAI'),
            Text('バージョン: 1.0.0'),
            SizedBox(height: 12),
            Text('最新の機能:'),
            Text('• チャットボット形式のUI'),
            Text('• リアルタイムプレビュー'),
            Text('• レスポンシブデザイン'),
            Text('• 音声入力対応'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}