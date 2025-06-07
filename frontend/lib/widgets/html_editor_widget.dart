import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/editor_provider.dart';

class HtmlEditorWidget extends StatefulWidget {
  const HtmlEditorWidget({super.key});

  @override
  State<HtmlEditorWidget> createState() => _HtmlEditorWidgetState();
}

class _HtmlEditorWidgetState extends State<HtmlEditorWidget> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, editorProvider, child) {
        // テキストコントローラーの内容を同期
        if (_textController.text != editorProvider.htmlContent) {
          _textController.text = editorProvider.htmlContent;
        }

        return Column(
          children: [
            // ツールバー
            _buildToolbar(editorProvider),

            // エディタ本体
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: 'HTMLコンテンツを入力してください...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  onChanged: (value) {
                    editorProvider.setHtmlContent(value);
                  },
                ),
              ),
            ),

            // ステータスバー
            _buildStatusBar(editorProvider),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(EditorProvider editorProvider) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Wrap(
        spacing: 8,
        children: [
          // テンプレート選択
          _buildToolbarButton(
            icon: Icons.article,
            label: 'シンプル',
            onPressed: () {
              editorProvider.applyTemplate('simple');
            },
          ),
          _buildToolbarButton(
            icon: Icons.chat_bubble,
            label: '吹き出し',
            onPressed: () {
              editorProvider.applyTemplate('bubble');
            },
          ),
          _buildToolbarButton(
            icon: Icons.palette,
            label: '季節',
            onPressed: () {
              editorProvider.applyTemplate('seasonal');
            },
          ),

          const SizedBox(width: 16),

          // カラーパレット
          _buildColorButton('🌸', 'spring', editorProvider),
          _buildColorButton('🌻', 'summer', editorProvider),
          _buildColorButton('🍂', 'autumn', editorProvider),
          _buildColorButton('❄️', 'winter', editorProvider),

          const SizedBox(width: 16),

          // HTMLタグ挿入
          _buildToolbarButton(
            icon: Icons.format_bold,
            label: 'Bold',
            onPressed: () => _insertTag('b'),
          ),
          _buildToolbarButton(
            icon: Icons.format_italic,
            label: 'Italic',
            onPressed: () => _insertTag('i'),
          ),
          _buildToolbarButton(
            icon: Icons.title,
            label: 'H1',
            onPressed: () => _insertTag('h1'),
          ),

          const SizedBox(width: 16),

          // 機能ボタン
          _buildToolbarButton(
            icon: Icons.preview,
            label: 'プレビュー',
            onPressed: () => _showPreview(editorProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 32),
      ),
    );
  }

  Widget _buildColorButton(
      String emoji, String season, EditorProvider editorProvider) {
    return GestureDetector(
      onTap: () {
        editorProvider.applyColorPalette(season);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _buildStatusBar(EditorProvider editorProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        children: [
          if (editorProvider.isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (editorProvider.errorMessage != null)
            Expanded(
              child: Text(
                'エラー: ${editorProvider.errorMessage}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          if (editorProvider.errorMessage == null && !editorProvider.isLoading)
            const Expanded(
              child: Text(
                '準備完了',
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
            ),
          Text(
            '文字数: ${editorProvider.htmlContent.length}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _insertTag(String tag) {
    final text = _textController.text;
    final selection = _textController.selection;

    if (selection.isValid) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = '<$tag>$selectedText</$tag>';

      final beforeSelection = text.substring(0, selection.start);
      final afterSelection = text.substring(selection.end);

      final updatedText = beforeSelection + newText + afterSelection;

      _textController.text = updatedText;
      _textController.selection = TextSelection.collapsed(
        offset: selection.start + newText.length,
      );

      // プロバイダーにも反映
      Provider.of<EditorProvider>(context, listen: false)
          .setHtmlContent(updatedText);
    }
  }

  void _showPreview(EditorProvider editorProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('HTMLプレビュー'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              editorProvider.htmlContent,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
