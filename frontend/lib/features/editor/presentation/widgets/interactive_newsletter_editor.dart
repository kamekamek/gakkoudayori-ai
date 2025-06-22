import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

/// インタラクティブ学級通信エディター
/// 
/// リアルタイムでテキスト編集とHTMLプレビューを同期表示し、
/// ADKエージェントとの連携による段階的な編集機能を提供
class InteractiveNewsletterEditor extends StatefulWidget {
  final String initialHtml;
  final String initialText;
  final Function(String html, String text)? onContentChanged;
  final Function(EditorAction action, Map<String, dynamic> params)? onEditorAction;
  final bool isLivePreview;
  final List<EditorTool> availableTools;

  const InteractiveNewsletterEditor({
    Key? key,
    this.initialHtml = '',
    this.initialText = '',
    this.onContentChanged,
    this.onEditorAction,
    this.isLivePreview = true,
    this.availableTools = const [],
  }) : super(key: key);

  @override
  State<InteractiveNewsletterEditor> createState() => _InteractiveNewsletterEditorState();
}

class _InteractiveNewsletterEditorState extends State<InteractiveNewsletterEditor>
    with TickerProviderStateMixin {
  late TextEditingController _textController;
  late TabController _tabController;
  
  String _currentHtml = '';
  String _currentText = '';
  bool _isTextMode = true;
  EditorMode _editorMode = EditorMode.split;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _tabController = TabController(length: 3, vsync: this);
    _currentHtml = widget.initialHtml;
    _currentText = widget.initialText;
    
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _currentText = _textController.text;
    });
    
    if (widget.isLivePreview) {
      _updateHtmlFromText(_currentText);
    }
    
    widget.onContentChanged?.call(_currentHtml, _currentText);
  }

  void _updateHtmlFromText(String text) {
    // 簡単なMarkdown風の変換
    String html = text
        .replaceAll(RegExp(r'^# (.+)$', multiLine: true), '<h1>\$1</h1>')
        .replaceAll(RegExp(r'^## (.+)$', multiLine: true), '<h2>\$1</h2>')
        .replaceAll(RegExp(r'^### (.+)$', multiLine: true), '<h3>\$1</h3>')
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), '<strong>\$1</strong>')
        .replaceAll(RegExp(r'\*(.+?)\*'), '<em>\$1</em>')
        .replaceAll(RegExp(r'\n\n'), '</p><p>')
        .replaceAll(RegExp(r'\n'), '<br>');

    if (!html.startsWith('<p>')) {
      html = '<p>$html</p>';
    }

    setState(() {
      _currentHtml = html;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_editorMode) {
      case EditorMode.textOnly:
        return _buildTextOnlyView();
      case EditorMode.previewOnly:
        return _buildPreviewOnlyView();
      case EditorMode.split:
      default:
        return _buildSplitView();
    }
  }

  Widget _buildSplitView() {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: Row(
            children: [
              // テキスト編集エリア
              Expanded(
                flex: 1,
                child: _buildTextEditor(),
              ),
              const VerticalDivider(width: 1),
              // プレビューエリア
              Expanded(
                flex: 1,
                child: _buildPreviewArea(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextOnlyView() {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(child: _buildTextEditor()),
      ],
    );
  }

  Widget _buildPreviewOnlyView() {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(child: _buildPreviewArea()),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text(
            '📝 内容編集',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // 表示モード切り替え
          SegmentedButton<EditorMode>(
            segments: const [
              ButtonSegment(
                value: EditorMode.textOnly,
                icon: Icon(Icons.edit_note, size: 16),
                label: Text('編集', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: EditorMode.split,
                icon: Icon(Icons.view_column, size: 16),
                label: Text('分割', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: EditorMode.previewOnly,
                icon: Icon(Icons.preview, size: 16),
                label: Text('プレビュー', style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {_editorMode},
            onSelectionChanged: (Set<EditorMode> selection) {
              setState(() {
                _editorMode = selection.first;
              });
            },
          ),
          const SizedBox(width: 8),
          // 編集ツール
          _buildEditorTools(),
        ],
      ),
    );
  }

  Widget _buildEditorTools() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...widget.availableTools.map((tool) => _buildToolButton(tool)),
        const SizedBox(width: 8),
        // AI拡張ボタン
        PopupMenuButton<String>(
          icon: const Icon(Icons.auto_awesome, size: 16),
          tooltip: 'AI機能',
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'improve',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('内容を改善'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'expand',
              child: Row(
                children: [
                  Icon(Icons.expand_more, size: 16),
                  SizedBox(width: 8),
                  Text('内容を拡張'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'summarize',
              child: Row(
                children: [
                  Icon(Icons.compress, size: 16),
                  SizedBox(width: 8),
                  Text('内容を要約'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'tone',
              child: Row(
                children: [
                  Icon(Icons.mood, size: 16),
                  SizedBox(width: 8),
                  Text('語調を調整'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            widget.onEditorAction?.call(
              EditorAction.aiAssist,
              {'type': value, 'content': _currentText},
            );
          },
        ),
      ],
    );
  }

  Widget _buildToolButton(EditorTool tool) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        icon: Icon(tool.icon, size: 16),
        tooltip: tool.label,
        onPressed: () {
          widget.onEditorAction?.call(tool.action, tool.params);
        },
      ),
    );
  }

  Widget _buildTextEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'テキスト編集',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_currentText.length} 文字',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextEditingHelp(),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: '学級通信の内容を入力してください...\n\n'
                    '# 見出し1\n'
                    '## 見出し2\n'
                    '**太字** *斜体* でフォーマット可能',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextEditingHelp() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.help_outline, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '# 見出し **太字** *斜体* の記法でフォーマット可能',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'リアルタイムプレビュー',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (widget.isLivePreview)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: _currentHtml.isEmpty
                    ? _buildEmptyPreview()
                    : HtmlWidget(
                        _currentHtml,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPreview() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'テキストを入力すると\nプレビューが表示されます',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// エディターのモード
enum EditorMode {
  textOnly,
  previewOnly,
  split,
}

/// エディターのアクション
enum EditorAction {
  insertHeading,
  insertImage,
  insertEmphasis,
  aiAssist,
  formatText,
  insertMedia,
}

/// エディターツール設定
class EditorTool {
  final String label;
  final IconData icon;
  final EditorAction action;
  final Map<String, dynamic> params;

  const EditorTool({
    required this.label,
    required this.icon,
    required this.action,
    this.params = const {},
  });

  static List<EditorTool> get defaultTools => [
    const EditorTool(
      label: '見出し1',
      icon: Icons.title,
      action: EditorAction.insertHeading,
      params: {'level': 1},
    ),
    const EditorTool(
      label: '見出し2',
      icon: Icons.subtitles,
      action: EditorAction.insertHeading,
      params: {'level': 2},
    ),
    const EditorTool(
      label: '太字',
      icon: Icons.format_bold,
      action: EditorAction.formatText,
      params: {'type': 'bold'},
    ),
    const EditorTool(
      label: '斜体',
      icon: Icons.format_italic,
      action: EditorAction.formatText,
      params: {'type': 'italic'},
    ),
    const EditorTool(
      label: '画像挿入',
      icon: Icons.image,
      action: EditorAction.insertImage,
    ),
  ];
}

/// エディター状態の管理
class EditorState {
  final String html;
  final String text;
  final int cursorPosition;
  final bool isModified;
  final DateTime lastModified;

  const EditorState({
    required this.html,
    required this.text,
    required this.cursorPosition,
    required this.isModified,
    required this.lastModified,
  });

  EditorState copyWith({
    String? html,
    String? text,
    int? cursorPosition,
    bool? isModified,
    DateTime? lastModified,
  }) {
    return EditorState(
      html: html ?? this.html,
      text: text ?? this.text,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      isModified: isModified ?? this.isModified,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}