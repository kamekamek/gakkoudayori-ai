import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../home/providers/newsletter_provider_v2.dart';
import '../../../../models/user_settings.dart';
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
  final _primaryTitleController = TextEditingController();
  final _defaultPatternController = TextEditingController();
  
  // タイトルテンプレート管理
  List<String> _seasonalTemplates = [];
  List<TitleTemplate> _customTemplates = [];
  bool _autoNumbering = true;
  int _currentNumber = 1;
  
  // UI状態
  bool _isLoading = false;
  bool _isSettingsComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSettings();
    });
  }

  void _loadCurrentSettings() {
    try {
      final provider = context.read<NewsletterProviderV2>();
      final settings = provider.userSettings;
      
      if (settings != null) {
        // 基本情報の設定（nullチェック付き）
        _schoolNameController.text = settings.schoolName.trim();
        _classNameController.text = settings.className.trim();
        _teacherNameController.text = settings.teacherName.trim();
        
        // タイトルテンプレート設定（nullチェック付き）
        final titleTemplates = settings.titleTemplates;
        _primaryTitleController.text = titleTemplates.primary.trim();
        _defaultPatternController.text = titleTemplates.defaultPattern.trim();
        
        // リストのnull安全性を確保
        _seasonalTemplates = titleTemplates.seasonal.where((item) => item.trim().isNotEmpty).toList();
        _customTemplates = titleTemplates.custom.where((template) => 
            template.name.trim().isNotEmpty && template.pattern.trim().isNotEmpty).toList();
        
        _autoNumbering = titleTemplates.autoNumbering;
        _currentNumber = titleTemplates.currentNumber > 0 ? titleTemplates.currentNumber : 1;
        
        _isSettingsComplete = settings.isComplete;
      } else {
        // 設定がない場合はデフォルト値を設定
        _schoolNameController.clear();
        _classNameController.clear();
        _teacherNameController.clear();
        _primaryTitleController.text = '学級だより○号';
        _defaultPatternController.text = '○年○組 学級通信';
        _seasonalTemplates = ['夏休み号', '冬休み号', '運動会号'];
        _customTemplates = [];
        _autoNumbering = true;
        _currentNumber = 1;
        _isSettingsComplete = false;
      }
      
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SettingsPage: 設定読み込みエラー: $e');
      }
      // エラー時はデフォルト状態を維持
    }
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _classNameController.dispose();
    _teacherNameController.dispose();
    _primaryTitleController.dispose();
    _defaultPatternController.dispose();
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 設定完了状況の表示
                if (!_isSettingsComplete) _buildIncompleteSettingsWarning(),
                
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
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _classNameController,
                      label: 'クラス名',
                      hint: '例: 1年1組',
                      icon: Icons.class_,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _teacherNameController,
                      label: '先生のお名前',
                      hint: '例: 田中太郎',
                      icon: Icons.person,
                      required: true,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveSettings,
                      icon: _isLoading 
                        ? const SizedBox(
                            width: 16, 
                            height: 16, 
                            child: CircularProgressIndicator(strokeWidth: 2)
                          )
                        : const Icon(Icons.save),
                      label: Text(_isLoading ? '保存中...' : '設定を保存'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // タイトルテンプレート設定セクション
                _buildSectionCard(
                  title: 'タイトルテンプレート管理',
                  icon: Icons.title,
                  children: [
                    Text(
                      '学級通信のタイトルパターンを設定します',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _primaryTitleController,
                      label: 'メインタイトルパターン',
                      hint: '例: 学級だより○号',
                      icon: Icons.format_quote,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _defaultPatternController,
                      label: 'デフォルトパターン',
                      hint: '例: ○年○組 学級通信',
                      icon: Icons.text_fields,
                    ),
                    const SizedBox(height: 16),
                    _buildAutoNumberingSwitch(),
                    if (_autoNumbering) ...[
                      const SizedBox(height: 16),
                      _buildCurrentNumberField(),
                    ],
                    const SizedBox(height: 20),
                    _buildSeasonalTemplatesSection(),
                    const SizedBox(height: 20),
                    _buildCustomTemplatesSection(),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // UI最適化設定セクション
                _buildSectionCard(
                  title: 'UI最適化設定',
                  icon: Icons.tune,
                  children: [
                    Text(
                      'ユーザー体験を向上させるためのUI設定',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildImageUploadLocationSetting(),
                    const SizedBox(height: 16),
                    _buildAutoGenerateTitleSetting(),
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

  Widget _buildIncompleteSettingsWarning() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.warning,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '設定が不完全です',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  Text(
                    '学校名、クラス名、先生名を入力してください',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
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
    bool required = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        errorText: required && controller.text.trim().isEmpty 
          ? '$labelは必須です' 
          : null,
      ),
    );
  }
  
  Widget _buildAutoNumberingSwitch() {
    return Row(
      children: [
        const Icon(Icons.format_list_numbered),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '自動ナンバリング',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Switch(
          value: _autoNumbering,
          onChanged: (value) {
            setState(() {
              _autoNumbering = value;
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildCurrentNumberField() {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: '現在の号数',
        hintText: '例: 1',
        prefixIcon: Icon(Icons.looks_one),
        border: OutlineInputBorder(),
      ),
      controller: TextEditingController(text: _currentNumber.toString()),
      onChanged: (value) {
        final number = int.tryParse(value);
        if (number != null && number > 0) {
          _currentNumber = number;
        }
      },
    );
  }
  
  Widget _buildSeasonalTemplatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sunny),
            const SizedBox(width: 8),
            Text(
              '季節のテンプレート',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addSeasonalTemplate,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._seasonalTemplates.asMap().entries.map((entry) {
          final index = entry.key;
          final template = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Chip(
                    label: Text(template),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeSeasonalTemplate(index),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildCustomTemplatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit),
            const SizedBox(width: 8),
            Text(
              'カスタムテンプレート',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addCustomTemplate,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._customTemplates.map((template) {
          return Card(
            child: ListTile(
              title: Text(template.name),
              subtitle: Text(template.pattern),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${template.usageCount}回使用'),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _removeCustomTemplate(template.id),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _saveSettings() async {
    // 入力値の清澄化とバリデーション
    final schoolName = _schoolNameController.text.trim();
    final className = _classNameController.text.trim();
    final teacherName = _teacherNameController.text.trim();
    
    if (schoolName.isEmpty || className.isEmpty || teacherName.isEmpty) {
      _showErrorSnackBar('学校名、クラス名、先生名は必須項目です');
      return;
    }
    
    // タイトルテンプレートのバリデーション
    final primaryTitle = _primaryTitleController.text.trim();
    final defaultPattern = _defaultPatternController.text.trim();
    
    if (primaryTitle.isEmpty) {
      _showErrorSnackBar('メインタイトルパターンを入力してください');
      return;
    }
    
    if (defaultPattern.isEmpty) {
      _showErrorSnackBar('デフォルトパターンを入力してください');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<NewsletterProviderV2>();
      
      // タイトルテンプレート設定を構築（清漄化済みの値を使用）
      final titleTemplates = TitleTemplates(
        primary: primaryTitle,
        seasonal: _seasonalTemplates.where((item) => item.trim().isNotEmpty).toList(),
        custom: _customTemplates.where((template) => 
            template.name.trim().isNotEmpty && template.pattern.trim().isNotEmpty).toList(),
        defaultPattern: defaultPattern,
        autoNumbering: _autoNumbering,
        currentNumber: _currentNumber > 0 ? _currentNumber : 1,
      );

      // saveUserSettingsが自動的にCREATE/UPDATEを判定（清澄化済みの値を使用）
      final success = await provider.saveUserSettings(
        schoolName: schoolName,
        className: className,
        teacherName: teacherName,
        titleTemplates: titleTemplates,
      );

      if (success) {
        _loadCurrentSettings(); // 設定を再読み込み
        _showSuccessSnackBar('設定を保存しました');
      } else {
        _showErrorSnackBar('設定の保存に失敗しました');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SettingsPage: 設定保存エラー: $e');
      }
      _showErrorSnackBar('エラーが発生しました: ${e.toString().length > 50 ? e.toString().substring(0, 50) + "..." : e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _addSeasonalTemplate() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('季節テンプレートを追加'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'テンプレート名',
              hintText: '例: 夏休み号',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _seasonalTemplates.add(controller.text.trim());
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('追加'),
            ),
          ],
        );
      },
    );
  }
  
  void _removeSeasonalTemplate(int index) {
    setState(() {
      _seasonalTemplates.removeAt(index);
    });
  }
  
  void _addCustomTemplate() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final patternController = TextEditingController();
        return AlertDialog(
          title: const Text('カスタムテンプレートを追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'テンプレート名',
                  hintText: '例: 遠足のお知らせ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: patternController,
                decoration: const InputDecoration(
                  labelText: 'パターン',
                  hintText: '例: 遠足のお知らせ（○月○日）',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty &&
                    patternController.text.trim().isNotEmpty) {
                  final newTemplate = TitleTemplate(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    pattern: patternController.text.trim(),
                    category: 'custom',
                    usageCount: 0,
                  );
                  setState(() {
                    _customTemplates.add(newTemplate);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('追加'),
            ),
          ],
        );
      },
    );
  }
  
  void _removeCustomTemplate(String templateId) {
    setState(() {
      _customTemplates.removeWhere((template) => template.id == templateId);
    });
  }

  void _openUserDictionary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserDictionaryWidget(
          userId: 'user_12345', // デフォルトユーザーID（実際のアプリでは認証済みユーザーIDを使用）
          onDictionaryUpdated: () {
            // 辞書更新時の処理（必要に応じて）
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('ユーザー辞書が更新されました'),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
                action: SnackBarAction(
                  label: '✕',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
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

  Widget _buildImageUploadLocationSetting() {
    final provider = context.read<NewsletterProviderV2>();
    final currentLocation = provider.uiPreferences.imageUploadLocation;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.image),
            const SizedBox(width: 8),
            Text(
              '画像アップロード位置',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '画像アップロードボタンを表示する場所を選択します',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('チャット入力エリア'),
                subtitle: const Text('チャットの入力欄に表示'),
                value: 'chat',
                groupValue: currentLocation,
                onChanged: (value) {
                  if (value != null) {
                    final newPrefs = provider.uiPreferences.copyWith(
                      imageUploadLocation: value,
                    );
                    provider.updateUiPreferences(newPrefs);
                  }
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('非表示'),
                subtitle: const Text('画像アップロードボタンを非表示'),
                value: 'hidden',
                groupValue: currentLocation,
                onChanged: (value) {
                  if (value != null) {
                    final newPrefs = provider.uiPreferences.copyWith(
                      imageUploadLocation: value,
                    );
                    provider.updateUiPreferences(newPrefs);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAutoGenerateTitleSetting() {
    final provider = context.read<NewsletterProviderV2>();
    final autoGenerate = provider.uiPreferences.autoGenerateTitle;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome),
            const SizedBox(width: 8),
            Text(
              'タイトル自動生成',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '学級通信のタイトルを自動的に生成するかどうかを設定します',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('タイトル自動生成を有効にする'),
          subtitle: const Text('チャット内容から適切なタイトルを自動生成します'),
          value: autoGenerate,
          onChanged: (value) {
            final newPrefs = provider.uiPreferences.copyWith(
              autoGenerateTitle: value,
            );
            provider.updateUiPreferences(newPrefs);
          },
        ),
        if (autoGenerate) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'テンプレート設定に基づいて、最適なタイトルが自動生成されます',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// エラーメッセージを表示するSnackBarを表示
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $message'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        ),
      );
    }
  }

  /// 成功メッセージを表示するSnackBarを表示
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $message'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          action: SnackBarAction(
            label: '✕',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }
}
