import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'html_editor_panel.dart';

class TextEditorPanel extends StatefulWidget {
  const TextEditorPanel({super.key});

  @override
  State<TextEditorPanel> createState() => _TextEditorPanelState();
}

class _TextEditorPanelState extends State<TextEditorPanel> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();
  bool _hasHistory = false;
  bool _isHtmlMode = true; // HTMLエディタモードの切り替え

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildTitleEditor(context),
          const SizedBox(height: 16),
          Expanded(
            child: _isHtmlMode 
                ? const HtmlEditorPanel()
                : _buildContentEditor(context),
          ),
          const SizedBox(height: 16),
          _buildToolbar(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(
          LucideIcons.edit,
          size: 24,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          'エディタ',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 16),
        // HTMLモード切り替えスイッチ
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isHtmlMode ? LucideIcons.code : LucideIcons.fileText,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 4),
              Switch(
                value: _isHtmlMode,
                onChanged: (value) => setState(() => _isHtmlMode = value),
                activeColor: AppTheme.primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 4),
              Text(
                _isHtmlMode ? 'HTML' : 'TEXT',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(LucideIcons.undo),
          onPressed: _hasHistory ? _undo : null,
          tooltip: '元に戻す',
        ),
        IconButton(
          icon: const Icon(LucideIcons.redo),
          onPressed: () => _redo(),
          tooltip: 'やり直し',
        ),
      ],
    );
  }

  Widget _buildTitleEditor(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'タイトル',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              focusNode: _titleFocus,
              decoration: InputDecoration(
                hintText: '学級通信のタイトルを入力してください',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentEditor(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '本文',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_contentController.text.length}文字',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _contentController,
                focusNode: _contentFocus,
                decoration: InputDecoration(
                  hintText: 'ここに学級通信の内容を入力してください...\n\n音声入力からテキストを追加することもできます。',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (value) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 基本書式
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolbarButton(
                  LucideIcons.bold,
                  '太字',
                  () => _formatText('bold'),
                ),
                _buildToolbarButton(
                  LucideIcons.italic,
                  '斜体',
                  () => _formatText('italic'),
                ),
                _buildToolbarButton(
                  LucideIcons.underline,
                  '下線',
                  () => _formatText('underline'),
                ),
                _buildToolbarButton(
                  LucideIcons.palette,
                  '色',
                  () => _showColorPicker(),
                ),
                _buildToolbarButton(
                  LucideIcons.heading,
                  '見出し',
                  () => _insertHeading(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // レイアウト
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolbarButton(
                  LucideIcons.list,
                  'リスト',
                  () => _insertList(),
                ),
                _buildToolbarButton(
                  LucideIcons.image,
                  '画像',
                  () => _insertImage(),
                ),
                _buildToolbarButton(
                  LucideIcons.messageCircle,
                  '吹き出し',
                  () => _insertBubble(),
                ),
                _buildToolbarButton(
                  LucideIcons.smile,
                  '絵文字',
                  () => _showEmojiPicker(),
                ),
                _buildToolbarButton(
                  LucideIcons.sparkles,
                  'AI提案',
                  () => _getAISuggestions(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton(
      IconData icon, String tooltip, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 2),
            Text(
              tooltip,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _undo() {
    // TODO: Undo機能の実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('元に戻しました'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _redo() {
    // TODO: Redo機能の実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('やり直しました'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _formatText(String format) {
    final selection = _contentController.selection;
    if (!selection.isValid) return;

    if (selection.isCollapsed) {
      // Expand to a zero-width range at the caret so replaceRange still works.
      _contentController.selection = selection.copyWith(
        baseOffset: selection.start,
        extentOffset: selection.start,
      );
    }

    final selectedText = _contentController.text.substring(
      selection.start,
      selection.end,
    );

    String formattedText;
    switch (format) {
      case 'bold':
        formattedText = '**$selectedText**';
        break;
      case 'italic':
        formattedText = '*$selectedText*';
        break;
      case 'underline':
        formattedText = '<u>$selectedText</u>';
        break;
      default:
        formattedText = selectedText;
    }

    _replaceSelection(formattedText);
  }

  void _insertHeading() {
    _insertAtCursor('## ');
  }

  void _insertList() {
    _insertAtCursor('- ');
  }

  void _insertImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('画像を挿入'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.upload),
              title: const Text('ファイルから選択'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: ファイル選択の実装
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('カメラで撮影'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: カメラ撮影の実装
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.palette),
              title: const Text('アイコンライブラリ'),
              onTap: () {
                Navigator.of(context).pop();
                _showIconLibrary();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _insertBubble() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('吹き出しを挿入'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.messageCircle),
              title: const Text('普通の吹き出し'),
              onTap: () {
                Navigator.of(context).pop();
                _insertAtCursor('\n<div class="bubble">ここにテキストを入力</div>\n');
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.heart),
              title: const Text('可愛い吹き出し'),
              onTap: () {
                Navigator.of(context).pop();
                _insertAtCursor(
                    '\n<div class="bubble cute">ここにテキストを入力</div>\n');
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.star),
              title: const Text('重要な吹き出し'),
              onTap: () {
                Navigator.of(context).pop();
                _insertAtCursor(
                    '\n<div class="bubble important">ここにテキストを入力</div>\n');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('色を選択'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Colors.red,
            Colors.blue,
            Colors.green,
            Colors.orange,
            Colors.purple,
            Colors.pink,
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
            AppTheme.accentColor,
          ].map((color) {
            return GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                _applyColor(color);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('絵文字を選択'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: GridView.count(
            crossAxisCount: 6,
            children: [
              '😊',
              '😃',
              '😄',
              '😆',
              '😍',
              '🥰',
              '👍',
              '👏',
              '🙌',
              '💪',
              '👶',
              '🧒',
              '📚',
              '✏️',
              '📝',
              '🎨',
              '🏃‍♂️',
              '⚽',
              '🌸',
              '🌞',
              '⭐',
              '💫',
              '🎉',
              '🎊',
              '❤️',
              '💚',
              '💙',
              '💛',
              '🧡',
              '💜',
            ].map((emoji) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  _insertAtCursor(emoji);
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey[100],
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showIconLibrary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アイコンライブラリ'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: DefaultTabController(
            length: 4,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: '学校'),
                    Tab(text: '季節'),
                    Tab(text: '活動'),
                    Tab(text: '感情'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildIconGrid(['🏫', '📚', '✏️', '📝', '🎨', '🧮']),
                      _buildIconGrid(['🌸', '🌞', '🍂', '❄️', '🌈', '⭐']),
                      _buildIconGrid(['🏃‍♂️', '⚽', '🎵', '🎨', '📖', '🧪']),
                      _buildIconGrid(['😊', '😃', '😍', '🥰', '👍', '💪']),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconGrid(List<String> icons) {
    return GridView.count(
      crossAxisCount: 4,
      children: icons.map((icon) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            _insertAtCursor(icon);
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _getAISuggestions() async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.sparkles, color: AppTheme.accentColor),
            SizedBox(width: 8),
            Text('AI提案を取得中'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.accentColor),
            SizedBox(height: 16),
            Text('AIが内容を分析して改善提案を生成しています...'),
          ],
        ),
      ),
    );

    try {
      // 実際のAI API呼び出し
      final result = await apiService.enhanceText(
        text: _contentController.text,
        style: 'friendly',
        gradeLevel: 'elementary',
      );

      if (mounted) {
        Navigator.of(context).pop();
        _showAISuggestionResults(result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI提案の取得に失敗しました: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showAISuggestionResults([Map<String, dynamic>? result]) {
    final suggestions = [
      '見出しを追加して読みやすくしましょう',
      '絵文字を使って親しみやすい印象にしましょう',
      '重要な部分を太字で強調しましょう',
      '箇条書きを使って整理しましょう',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI提案'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: suggestions.map((suggestion) {
            return ListTile(
              leading: const Icon(LucideIcons.lightbulb,
                  color: AppTheme.accentColor),
              title: Text(suggestion),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: 提案の適用
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('提案を適用しました: $suggestion'),
                    backgroundColor: AppTheme.accentColor,
                  ),
                );
              },
            );
          }).toList(),
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

  void _insertAtCursor(String text) {
    final selection = _contentController.selection;

    // 選択が無効な場合はカーソルを先頭に設定
    if (!selection.isValid) {
      _contentController.selection = const TextSelection.collapsed(offset: 0);
    }

    final validSelection = _contentController.selection;
    final newText = _contentController.text.replaceRange(
      validSelection.start,
      validSelection.end,
      text,
    );

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: validSelection.start + text.length,
      ),
    );

    setState(() {}); // UI更新をトリガー
  }

  void _replaceSelection(String text) {
    final selection = _contentController.selection;

    // 選択が無効な場合はカーソルを先頭に設定
    if (!selection.isValid) {
      _contentController.selection = const TextSelection.collapsed(offset: 0);
    }

    final validSelection = _contentController.selection;
    final newText = _contentController.text.replaceRange(
      validSelection.start,
      validSelection.end,
      text,
    );

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: validSelection.start + text.length,
      ),
    );

    setState(() {}); // UI更新をトリガー
  }

  void _applyColor(Color color) {
    final selection = _contentController.selection;
    if (selection.isValid) {
      final selectedText = _contentController.text.substring(
        selection.start,
        selection.end,
      );

      final colorHex = '#${color.value.toRadixString(16).substring(2)}';
      final formattedText =
          '<span style="color: $colorHex">$selectedText</span>';

      _replaceSelection(formattedText);
    }

    setState(() {}); // UI更新をトリガー
  }
}
