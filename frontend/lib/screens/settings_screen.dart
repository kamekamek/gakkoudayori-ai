import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedAccuracy = 'balanced'; // デフォルトはバランス設定
  bool _isDriveConnected = false; // Google Drive接続状態

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneralSettings(context),
            const SizedBox(height: 24),
            _buildVoiceSettings(context),
            const SizedBox(height: 24),
            _buildIntegrationSettings(context),
            const SizedBox(height: 24),
            _buildUserDictionary(context),
            const SizedBox(height: 24),
            _buildAboutSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext context) {
    final appState = context.watch<AppState>();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.settings,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '一般設定',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // テーマ設定
            ListTile(
              leading: Icon(
                appState.themeMode == ThemeMode.dark
                    ? LucideIcons.moon
                    : LucideIcons.sun,
                color: AppTheme.primaryColor,
              ),
              title: const Text('表示テーマ'),
              subtitle: Text(
                appState.themeMode == ThemeMode.dark ? 'ダークモード' : 'ライトモード',
              ),
              trailing: Switch(
                value: appState.themeMode == ThemeMode.dark,
                onChanged: (value) => appState.toggleTheme(),
                activeColor: AppTheme.primaryColor,
              ),
            ),
            
            const Divider(),
            
            // 季節テーマ設定
            ListTile(
              leading: Icon(
                _getSeasonIcon(appState.currentSeasonName),
                color: AppTheme.primaryColor,
              ),
              title: const Text('季節テーマ'),
              subtitle: Text('現在: ${appState.currentSeasonName}'),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => _showSeasonSelector(context),
            ),
            
            const Divider(),
            
            // 自動保存
SwitchListTile(
   secondary: const Icon(
     LucideIcons.save,
     color: AppTheme.primaryColor,
   ),
   title: const Text('自動保存'),
   subtitle: const Text('編集内容を自動的に保存'),
  value: false,
   onChanged: (value) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('自動保存機能は開発中です'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
   },
  // Disable until implemented
  enabled: false,
 ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 600));
  }

  Widget _buildVoiceSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.mic,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '音声設定',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // ノイズ抑制
            SwitchListTile(
              secondary: const Icon(
                LucideIcons.volume2,
                color: AppTheme.primaryColor,
              ),
              title: const Text('ノイズ抑制'),
              subtitle: const Text('背景雑音を軽減して認識精度を向上'),
              value: true,
              onChanged: (value) {
                // TODO: ノイズ抑制設定
              },
            ),
            
            const Divider(),
            
            // 自動句読点
            SwitchListTile(
              secondary: const Icon(
                LucideIcons.type,
                color: AppTheme.primaryColor,
              ),
              title: const Text('自動句読点'),
              subtitle: const Text('話し方に応じて句読点を自動挿入'),
              value: true,
              onChanged: (value) {
                // TODO: 自動句読点設定
              },
            ),
            
            const Divider(),
            
            // 音声認識精度
            ListTile(
              leading: const Icon(
                LucideIcons.target,
                color: AppTheme.primaryColor,
              ),
              title: const Text('認識精度設定'),
              subtitle: const Text('速度重視 ⇄ 精度重視'),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => _showAccuracySettings(context),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(delay: const Duration(milliseconds: 100), duration: const Duration(milliseconds: 600));
  }

  Widget _buildIntegrationSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.link,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '連携設定',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Google Classroom
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  LucideIcons.graduationCap,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              title: const Text('Google Classroom'),
              subtitle: const Text('未接続'),
              trailing: ElevatedButton(
                onPressed: () => _connectGoogleClassroom(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('接続'),
              ),
            ),
            
            const Divider(),
            
            // Google Drive
ListTile(
   leading: Container(
     width: 32,
     height: 32,
     decoration: BoxDecoration(
       color: Colors.blue,
       borderRadius: BorderRadius.circular(6),
     ),
     child: const Icon(
       LucideIcons.folderOpen,
       color: Colors.white,
       size: 18,
     ),
   ),
   title: const Text('Google Drive'),
  subtitle: Text(_isDriveConnected ? '接続済み' : '未接続'),
   trailing: ElevatedButton(
    onPressed: _isDriveConnected ? () => _configureGoogleDrive(context) : () => _connectGoogleDrive(context),
     style: ElevatedButton.styleFrom(
       backgroundColor: Colors.blue,
       foregroundColor: Colors.white,
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
     ),
    child: Text(_isDriveConnected ? '設定' : '接続'),
   ),
 ),
            
            const Divider(),
            
            // LINE通知
            SwitchListTile(
              secondary: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  LucideIcons.messageCircle,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              title: const Text('LINE通知'),
              subtitle: const Text('学級通信配信時に保護者へ自動通知'),
              value: false,
              onChanged: (value) {
                if (value) {
                  _setupLineNotification(context);
                } else {
                  // TODO: LINE通知無効化
                }
              },
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(delay: const Duration(milliseconds: 200), duration: const Duration(milliseconds: 600));
  }

  Widget _buildUserDictionary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.book,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'ユーザー辞書',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              '音声認識の精度を向上させるため、よく使用する用語を登録できます。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 登録済み用語数
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.bookOpen,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
FutureBuilder<int>(
  future: _getUserDictionaryCount(),
  builder: (context, snapshot) {
    return Text(
      '登録済み用語: ${snapshot.data ?? 0}件',
       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
         color: AppTheme.primaryColor,
         fontWeight: FontWeight.w500,
       ),
    );
  },
),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // アクションボタン
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addUserWord(context),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('用語追加'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _manageUserDictionary(context),
                    icon: const Icon(LucideIcons.edit, size: 16),
                    label: const Text('辞書管理'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(delay: const Duration(milliseconds: 300), duration: const Duration(milliseconds: 600));
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.info,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'アプリについて',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(LucideIcons.smartphone, color: AppTheme.primaryColor),
              title: const Text('バージョン'),
              subtitle: const Text('1.0.0'),
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(LucideIcons.helpCircle, color: AppTheme.primaryColor),
              title: const Text('ヘルプ・チュートリアル'),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => _showHelp(context),
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(LucideIcons.messageSquare, color: AppTheme.primaryColor),
              title: const Text('フィードバック'),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => _showFeedback(context),
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(LucideIcons.shield, color: AppTheme.primaryColor),
              title: const Text('プライバシーポリシー'),
              trailing: const Icon(LucideIcons.externalLink, size: 16),
              onTap: () => _showPrivacyPolicy(context),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(delay: const Duration(milliseconds: 400), duration: const Duration(milliseconds: 600));
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

  void _showSeasonSelector(BuildContext context) {
    final appState = context.read<AppState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('季節テーマを選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSeasonOption(context, '春', Icons.local_florist, AppTheme.springColors[0], appState),
            _buildSeasonOption(context, '夏', Icons.wb_sunny, AppTheme.summerColors[0], appState),
            _buildSeasonOption(context, '秋', Icons.eco, AppTheme.autumnColors[0], appState),
            _buildSeasonOption(context, '冬', Icons.ac_unit, AppTheme.winterColors[0], appState),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonOption(BuildContext context, String season, IconData icon, Color color, AppState appState) {
    final isSelected = appState.currentSeasonName == season;
    
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(season),
      trailing: isSelected ? const Icon(LucideIcons.check, color: AppTheme.primaryColor) : null,
      onTap: () {
        appState.setSeason(['春', '夏', '秋', '冬'].indexOf(season));
        Navigator.of(context).pop();
      },
    );
  }

  void _showAccuracySettings(BuildContext context) {
    // ダイアログ内で使用する一時的な選択状態
    String tempSelectedAccuracy = _selectedAccuracy;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('音声認識精度設定'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('速度重視'),
                subtitle: const Text('高速だが精度は標準'),
                value: 'speed',
                groupValue: tempSelectedAccuracy,
                onChanged: (value) {
                  setDialogState(() {
                    tempSelectedAccuracy = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('バランス'),
                subtitle: const Text('速度と精度のバランス（推奨）'),
                value: 'balanced',
                groupValue: tempSelectedAccuracy,
                onChanged: (value) {
                  setDialogState(() {
                    tempSelectedAccuracy = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('精度重視'),
                subtitle: const Text('時間をかけて高精度で認識'),
                value: 'accuracy',
                groupValue: tempSelectedAccuracy,
                onChanged: (value) {
                  setDialogState(() {
                    tempSelectedAccuracy = value!;
                  });
                },
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
                setState(() {
                  _selectedAccuracy = tempSelectedAccuracy;
                });
                Navigator.of(context).pop();
                
                // 設定保存完了メッセージ
                String accuracyText;
                switch (_selectedAccuracy) {
                  case 'speed':
                    accuracyText = '速度重視';
                    break;
                  case 'accuracy':
                    accuracyText = '精度重視';
                    break;
                  default:
                    accuracyText = 'バランス';
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('音声認識精度を「$accuracyText」に設定しました'),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _connectGoogleClassroom(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Classroom連携'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.graduationCap, size: 48, color: Colors.green),
            SizedBox(height: 16),
            Text('Google Classroomとの連携を行います。'),
            SizedBox(height: 8),
            Text('学級通信を自動でクラスに投稿できるようになります。'),
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
              // TODO: 実際のOAuth認証処理
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Google Classroom連携機能は開発中です'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('連携する'),
          ),
        ],
      ),
    );
  }

  void _connectGoogleDrive(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Drive連携'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.folderOpen, size: 48, color: Colors.blue),
            SizedBox(height: 16),
            Text('Google Driveとの連携を行います。'),
            SizedBox(height: 8),
            Text('学級通信をDriveに自動保存できるようになります。'),
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
              setState(() {
                _isDriveConnected = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Google Driveと連携しました'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('連携する'),
          ),
        ],
      ),
    );
  }

  void _configureGoogleDrive(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Drive設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.folder),
              title: const Text('保存フォルダ'),
              subtitle: const Text('/学級通信/2024'),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () {
                // TODO: フォルダ選択
              },
            ),
            SwitchListTile(
              title: const Text('月別フォルダ自動作成'),
              subtitle: const Text('YYYY/MM形式で自動作成'),
              value: true,
              onChanged: (value) {
                // TODO: 設定保存
              },
            ),
            SwitchListTile(
              title: const Text('自動共有'),
              subtitle: const Text('保護者に閲覧権限を自動付与'),
              value: false,
              onChanged: (value) {
                // TODO: 設定保存
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(LucideIcons.unlink, color: Colors.red),
              title: const Text('連携を解除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                _disconnectGoogleDrive(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _disconnectGoogleDrive(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('連携解除の確認'),
        content: const Text('Google Driveとの連携を解除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isDriveConnected = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Google Driveとの連携を解除しました'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('解除'),
          ),
        ],
      ),
    );
  }

  void _setupLineNotification(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('LINE通知設定'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('LINE通知を有効にするには、LINE Botの設定が必要です。'),
            SizedBox(height: 16),
            Text('管理者にお問い合わせください。'),
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

  void _addUserWord(BuildContext context) {
    final wordController = TextEditingController();
    final readingController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('用語を追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: wordController,
              decoration: const InputDecoration(
                labelText: '用語',
                hintText: '例: 体育発表会',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: readingController,
              decoration: const InputDecoration(
                labelText: '読み方',
                hintText: '例: たいいくはっぴょうかい',
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
    final word = wordController.text.trim();
    final reading = readingController.text.trim();
    
    if (word.isEmpty || reading.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('用語と読み方を入力してください'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    // Validate reading contains only hiragana
    final hiraganaRegex = RegExp(r'^[ぁ-ん]+$');
    if (!hiraganaRegex.hasMatch(reading)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('読み方はひらがなで入力してください'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
     // TODO: 用語登録処理
     Navigator.of(context).pop();
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(
        content: Text('用語「$word」を追加しました'),
         backgroundColor: AppTheme.accentColor,
       ),
     );
   },
   child: const Text('追加'),
 ),
        ],
      ),
    );
  }

  void _manageUserDictionary(BuildContext context) {
    // TODO: ユーザー辞書管理画面の実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ユーザー辞書管理画面は開発中です'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showHelp(BuildContext context) {
    // TODO: ヘルプ画面の実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ヘルプ機能は開発中です'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showFeedback(BuildContext context) {
    // TODO: フィードバック機能の実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('フィードバック機能は開発中です'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    // TODO: プライバシーポリシー表示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('プライバシーポリシーページは開発中です'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Future<int> _getUserDictionaryCount() async {
    // TODO: 実際のユーザー辞書データ取得
    // 現在はサンプル値を返す
    await Future.delayed(const Duration(milliseconds: 100));
    return 5; // サンプル登録数
  }
}