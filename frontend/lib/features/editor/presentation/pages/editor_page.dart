import 'package:flutter/material.dart';
import '../widgets/quill_editor_widget.dart';
// import '../widgets/voice_input_widget.dart'; // 一時無効化
import 'package:provider/provider.dart';
import '../../providers/quill_editor_provider.dart';

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
                Icon(Icons.edit,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'エディタ状態: ${_isEditorReady ? "準備完了" : "読み込み中"}',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                if (_currentContent.isNotEmpty) ...[
                  Icon(Icons.text_fields,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    '文字数: ${_currentContent.length}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                  color: Theme.of(context)
                      .colorScheme
                      .shadow
                      .withValues(alpha: 0.1),
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
                  onPressed:
                      _isEditorReady ? () => _insertFormat('**太字**') : null,
                ),
                _buildActionButton(
                  icon: Icons.format_list_bulleted,
                  label: 'リスト',
                  onPressed: _isEditorReady
                      ? () => _insertFormat('\n• リスト項目\n')
                      : null,
                ),
                _buildActionButton(
                  icon: Icons.image,
                  label: '画像',
                  onPressed:
                      _isEditorReady ? () => _insertFormat('[画像を挿入]') : null,
                ),
                _buildActionButton(
                  icon: Icons.palette,
                  label: 'テーマ',
                  onPressed: _isEditorReady ? _showThemeDialog : null,
                ),
                _buildActionButton(
                  icon: Icons.mic,
                  label: 'AI音声',
                  onPressed: _isEditorReady ? _showVoiceInputDialog : null,
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.palette,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '季節テーマの選択',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                '学級通信にぴったりの季節感を選んでください',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              // 季節テーマ選択グリッド
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _buildSeasonThemeCard(
                    'default',
                    '標準',
                    Icons.auto_awesome,
                    const Color(0xFF4CAF50),
                    '一年中使える標準テーマ',
                  ),
                  _buildSeasonThemeCard(
                    'spring',
                    '春',
                    Icons.local_florist,
                    const Color(0xFFFF9EAA),
                    '桜咲く新学期の季節',
                  ),
                  _buildSeasonThemeCard(
                    'summer',
                    '夏',
                    Icons.wb_sunny,
                    const Color(0xFF51CF66),
                    '緑あふれる夏休み',
                  ),
                  _buildSeasonThemeCard(
                    'autumn',
                    '秋',
                    Icons.eco,
                    const Color(0xFFE67700),
                    '紅葉美しい学習の秋',
                  ),
                  _buildSeasonThemeCard(
                    'winter',
                    '冬',
                    Icons.ac_unit,
                    const Color(0xFF4DABF7),
                    '雪降る静寂の季節',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonThemeCard(
    String themeId,
    String label,
    IconData icon,
    Color color,
    String description,
  ) {
    return InkWell(
      onTap: () async {
        await _applySeasonTheme(themeId, label);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applySeasonTheme(String themeId, String themeLabel) async {
    try {
      final state = _editorKey.currentState;
      if (state != null) {
        // Quillエディタにテーマを即座に適用
        await state.setTheme(themeId);

        // プロバイダーの状態も更新
        final provider =
            Provider.of<QuillEditorProvider>(context, listen: false);
        provider.changeTheme(themeId);

        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('テーマを「$themeLabel」に変更しました'),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // エラーハンドリング
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('テーマの変更に失敗しました: $e'),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showVoiceInputDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(20),
          // VoiceInputWidget一時無効化 - Web API対応中
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mic_off,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                const Text(
                  '音声入力機能は準備中です',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Web Audio APIの最新対応を行っています。\nしばらくお待ちください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('閉じる'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _insertGeneratedContent(String content) async {
    final state = _editorKey.currentState;
    if (state != null) {
      // Quillエディタに生成されたコンテンツを設定
      await state.setHTML(content);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI生成コンテンツをエディタに設定しました'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

// Helper extension to access state methods
extension QuillEditorWidgetExtension on QuillEditorWidget {
  QuillEditorWidgetState? get currentState =>
      (key as GlobalKey<QuillEditorWidgetState>?)?.currentState;
}
