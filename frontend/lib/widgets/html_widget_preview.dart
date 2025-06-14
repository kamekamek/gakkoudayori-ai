import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

/// flutter_widget_from_htmlを使用したHTMLプレビューウィジェット
/// HtmlElementViewの問題を回避し、適切なHTML表示を提供
class HtmlWidgetPreview extends StatefulWidget {
  final String htmlContent;
  final double height;
  final Function(String)? onContentChanged;
  final bool isEditable;

  const HtmlWidgetPreview({
    Key? key,
    required this.htmlContent,
    this.height = 500,
    this.onContentChanged,
    this.isEditable = false,
  }) : super(key: key);

  @override
  State<HtmlWidgetPreview> createState() => _HtmlWidgetPreviewState();
}

class _HtmlWidgetPreviewState extends State<HtmlWidgetPreview> {
  late TextEditingController _editController;
  bool _isEditing = false;
  String _currentHtml = '';

  @override
  void initState() {
    super.initState();
    _currentHtml = widget.htmlContent;
    _editController =
        TextEditingController(text: _extractTextFromHtml(_currentHtml));
  }

  @override
  void didUpdateWidget(HtmlWidgetPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlContent != widget.htmlContent) {
      _currentHtml = widget.htmlContent;
      if (!_isEditing) {
        _editController.text = _extractTextFromHtml(_currentHtml);
      }
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  /// HTMLからプレーンテキストを抽出
  String _extractTextFromHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// テキストをHTMLに変換（簡易版）
  String _convertTextToHtml(String text) {
    final lines = text.split('\n');
    final htmlLines = lines.map((line) {
      if (line.trim().isEmpty) return '<br>';
      return '<p>${line.trim()}</p>';
    }).join('\n');

    return '''
    <div class="newsletter-container">
      <style>
        .newsletter-container {
          max-width: 800px;
          margin: 0 auto;
          padding: 20px;
          font-family: 'Hiragino Sans', 'Yu Gothic', sans-serif;
          line-height: 1.6;
          background: white;
        }
        h1, h2, h3 { color: #2c3e50; margin-top: 20px; }
        p { margin-bottom: 12px; }
        .header { text-align: center; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        .date { text-align: right; color: #7f8c8d; font-size: 14px; }
        .signature { margin-top: 30px; text-align: right; }
      </style>
      $htmlLines
    </div>
    ''';
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _saveEdit() {
    final newHtml = _convertTextToHtml(_editController.text);
    setState(() {
      _currentHtml = newHtml;
      _isEditing = false;
    });

    if (widget.onContentChanged != null) {
      widget.onContentChanged!(newHtml);
    }

    print('📝 [HtmlWidget] 編集内容保存: ${newHtml.length}文字');
  }

  void _cancelEdit() {
    setState(() {
      _editController.text = _extractTextFromHtml(_currentHtml);
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 編集コントロール
          if (widget.isEditable) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit : Icons.preview,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isEditing ? '編集モード' : 'プレビューモード',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  if (_isEditing) ...[
                    TextButton(
                      onPressed: _cancelEdit,
                      child: const Text('キャンセル'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveEdit,
                      child: const Text('保存'),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: _startEditing,
                      child: const Text('編集'),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // コンテンツ表示
          Expanded(
            child: _isEditing ? _buildEditor() : _buildPreview(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _editController,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          hintText: 'ここに内容を入力してください...',
          border: InputBorder.none,
        ),
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: HtmlWidget(
        _currentHtml,
        textStyle: const TextStyle(
          fontSize: 14,
          height: 1.5,
        ),
        customStylesBuilder: (element) {
          // カスタムスタイリング
          if (element.localName == 'h1') {
            return {
              'color': '#2c3e50',
              'font-size': '24px',
              'font-weight': 'bold',
              'margin-bottom': '16px',
            };
          }
          if (element.localName == 'h2') {
            return {
              'color': '#34495e',
              'font-size': '20px',
              'font-weight': 'bold',
              'margin-bottom': '12px',
            };
          }
          if (element.localName == 'p') {
            return {
              'margin-bottom': '12px',
              'line-height': '1.6',
            };
          }
          return null;
        },
        onTapUrl: (url) {
          print('🔗 リンクタップ: $url');
          return true;
        },
      ),
    );
  }
}
