import 'package:flutter/material.dart';
import '../widgets/quill_editor_widget.dart';

/// エディタページ - Quill.jsエディタのメイン画面
class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final GlobalKey<QuillEditorWidgetState> _editorKey = GlobalKey();
  String _currentContent = '';
  bool _isEditorReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ゆとり職員室 - 学級通信エディタ'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isEditorReady ? _saveContent : null,
            tooltip: '保存',
          ),
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: _isEditorReady ? _showPreview : null,
            tooltip: 'プレビュー',
          ),
        ],
      ),
      body: Column(
        children: [
          // エディタ統計情報
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'エディタ状態: ${_isEditorReady ? "準備完了" : "読み込み中"}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                if (_currentContent.isNotEmpty) ...[
                  Icon(Icons.text_fields, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    '文字数: ${_currentContent.length}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          
          // メインエディタエリア
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: QuillEditorWidget(
                key: _editorKey,
                initialContent: '<h1>学級通信のタイトル</h1><p>ここに内容を入力してください。</p>',
                onContentChanged: (content) {
                  setState(() {
                    _currentContent = content;
                  });
                },
                onReady: () {
                  setState(() {
                    _isEditorReady = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('エディタの準備が完了しました'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                onSelectionChanged: (selection) {
                  debugPrint('Selection changed: $selection');
                },
              ),
            ),
          ),
          
          // アクションボタンバー
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.format_bold,
                  label: '太字',
                  onPressed: _isEditorReady ? () => _insertFormat('**太字**') : null,
                ),
                _buildActionButton(
                  icon: Icons.format_list_bulleted,
                  label: 'リスト',
                  onPressed: _isEditorReady ? () => _insertFormat('\n• リスト項目\n') : null,
                ),
                _buildActionButton(
                  icon: Icons.image,
                  label: '画像',
                  onPressed: _isEditorReady ? () => _insertFormat('[画像を挿入]') : null,
                ),
                _buildActionButton(
                  icon: Icons.palette,
                  label: 'テーマ',
                  onPressed: _isEditorReady ? _showThemeDialog : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          iconSize: 28,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  void _saveContent() async {
    final state = _editorKey.currentState;
    if (state != null) {
      final html = await state.getHTML();
      if (html != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('コンテンツを保存しました (${html.length} 文字)'),
            duration: const Duration(seconds: 2),
          ),
        );
        debugPrint('Saved HTML: $html');
      }
    }
  }

  void _showPreview() async {
    final state = _editorKey.currentState;
    if (state != null) {
      final html = await state.getHTML();
      if (html != null && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('プレビュー'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: SelectableText(
                  html,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
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
    }
  }

  void _insertFormat(String format) async {
    final state = _editorKey.currentState;
    if (state != null) {
      await state.insertText(format);
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('季節テーマの選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('default', '標準', Colors.blue),
            _buildThemeOption('spring', '春', Colors.pink),
            _buildThemeOption('summer', '夏', Colors.green),
            _buildThemeOption('autumn', '秋', Colors.orange),
            _buildThemeOption('winter', '冬', Colors.indigo),
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

  Widget _buildThemeOption(String theme, String label, Color color) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color),
      title: Text(label),
      onTap: () async {
        final state = _editorKey.currentState;
        if (state != null) {
          await state.setTheme(theme);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('テーマを「$label」に変更しました'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }
}

// Helper extension to access state methods
extension QuillEditorWidgetExtension on QuillEditorWidget {
  QuillEditorWidgetState? get currentState => 
      (key as GlobalKey<QuillEditorWidgetState>?)?.currentState;
}