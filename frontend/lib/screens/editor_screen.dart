import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/editor_provider.dart';
import '../widgets/html_editor_widget.dart';

class EditorScreen extends StatelessWidget {
  final String? documentId;

  const EditorScreen({super.key, this.documentId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('学級通信エディタ'),
          actions: [
            Consumer<EditorProvider>(
              builder: (context, editorProvider, child) {
                return IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: editorProvider.isLoading
                      ? null
                      : () {
                          // 保存処理
                          _saveDocument(context, editorProvider);
                        },
                );
              },
            ),
            Consumer<EditorProvider>(
              builder: (context, editorProvider, child) {
                return IconButton(
                  icon: const Icon(Icons.preview),
                  onPressed: editorProvider.isLoading
                      ? null
                      : () {
                          // プレビュー表示
                          _showPreview(context, editorProvider);
                        },
                );
              },
            ),
          ],
        ),
        body: const Padding(
          padding: EdgeInsets.all(16.0),
          child: HtmlEditorWidget(),
        ),
      ),
    );
  }

  void _saveDocument(BuildContext context, EditorProvider editorProvider) {
    // TODO: ドキュメント保存処理を実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('保存機能は後で実装されます'),
      ),
    );
  }

  void _showPreview(BuildContext context, EditorProvider editorProvider) {
    // TODO: プレビュー表示を実装
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレビュー'),
        content: SingleChildScrollView(
          child: Text(editorProvider.htmlContent),
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
