import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// シンプルなHTML編集ウィジェット
/// HtmlElementViewの代替として、軽量で確実な編集機能を提供
class SimpleHtmlEditorWidget extends StatefulWidget {
  final String initialContent;
  final Function(String html)? onContentChanged;
  final double height;

  const SimpleHtmlEditorWidget({
    Key? key,
    required this.initialContent,
    this.onContentChanged,
    this.height = 500,
  }) : super(key: key);

  @override
  State<SimpleHtmlEditorWidget> createState() => _SimpleHtmlEditorWidgetState();
}

class _SimpleHtmlEditorWidgetState extends State<SimpleHtmlEditorWidget> {
  late TextEditingController _controller;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: _extractTextFromHtml(widget.initialContent));
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_isModified) {
      setState(() {
        _isModified = true;
      });
    }
  }

  /// HTMLからテキスト部分を抽出（簡易版）
  String _extractTextFromHtml(String html) {
    // HTMLタグを除去してテキストのみを抽出
    String text = html
        .replaceAll(RegExp(r'<[^>]*>'), '\n')
        .replaceAll(RegExp(r'\n+'), '\n')
        .trim();

    return text;
  }

  /// テキストをHTMLに変換（簡易版）
  String _convertTextToHtml(String text) {
    final lines = text.split('\n');
    final htmlLines = <String>[];

    for (String line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // 簡単なHTMLフォーマット
      if (trimmed.length > 50) {
        htmlLines.add('<p>$trimmed</p>');
      } else if (trimmed.endsWith('：') || trimmed.endsWith(':')) {
        htmlLines.add('<h3>$trimmed</h3>');
      } else {
        htmlLines.add('<p>$trimmed</p>');
      }
    }

    return htmlLines.join('\n');
  }

  void _saveChanges() {
    if (_isModified && widget.onContentChanged != null) {
      final htmlContent = _convertTextToHtml(_controller.text);
      widget.onContentChanged!(htmlContent);

      setState(() {
        _isModified = false;
      });

      if (kDebugMode) debugPrint('📝 [SimpleEditor] 編集内容保存: ${htmlContent.length}文字');

      // 保存完了のフィードバック
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 編集内容を保存しました'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green[600],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(
            color: _isModified ? Colors.blue[300]! : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // ツールバー
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  'テキスト編集モード',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                if (_isModified) ...[
                  TextButton.icon(
                    onPressed: _saveChanges,
                    icon: Icon(Icons.save, size: 16),
                    label: Text('保存'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[600],
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
                  SizedBox(width: 8),
                ],
                Text(
                  _isModified ? '未保存' : '保存済み',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isModified ? Colors.orange[600] : Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // エディタ部分
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText:
                      '学級通信の内容を編集してください...\n\n・短い行は見出しになります\n・長い行は段落になります\n・空行で区切ってください',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  fontFamily: 'Hiragino Sans',
                ),
                onSubmitted: (_) => _saveChanges(),
              ),
            ),
          ),

          // フッター
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                SizedBox(width: 6),
                Text(
                  'Ctrl+Enter で保存 | 編集後は必ず保存ボタンを押してください',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
