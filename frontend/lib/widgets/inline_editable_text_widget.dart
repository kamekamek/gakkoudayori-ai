import 'package:flutter/material.dart';

/// インライン編集可能なテキストウィジェット
class InlineEditableTextWidget extends StatefulWidget {
  final String initialText;
  final TextStyle? textStyle;
  final Function(String) onTextChanged;
  final String? hintText;
  final bool multiline;
  final EdgeInsets padding;

  const InlineEditableTextWidget({
    super.key,
    required this.initialText,
    required this.onTextChanged,
    this.textStyle,
    this.hintText,
    this.multiline = false,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  State<InlineEditableTextWidget> createState() => _InlineEditableTextWidgetState();
}

class _InlineEditableTextWidgetState extends State<InlineEditableTextWidget> {
  late TextEditingController _controller;
  bool _isEditing = false;
  FocusNode? _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode?.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode?.requestFocus();
    });
  }

  void _stopEditing() {
    setState(() {
      _isEditing = false;
    });
    widget.onTextChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
          borderRadius: BorderRadius.circular(4),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: widget.textStyle,
          maxLines: widget.multiline ? null : 1,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: widget.hintText,
            contentPadding: EdgeInsets.zero,
          ),
          onSubmitted: (_) => _stopEditing(),
          onTapOutside: (_) => _stopEditing(),
        ),
      );
    }

    return GestureDetector(
      onTap: _startEditing,
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _controller.text.isEmpty 
                    ? (widget.hintText ?? 'テキストを入力')
                    : _controller.text,
                style: _controller.text.isEmpty 
                    ? widget.textStyle?.copyWith(
                        color: Theme.of(context).hintColor,
                        fontStyle: FontStyle.italic,
                      )
                    : widget.textStyle,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.edit,
              size: 16,
              color: Theme.of(context).hintColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// インライン編集可能なHTMLプレビュー用ウィジェット
class InlineEditableHtmlPreview extends StatefulWidget {
  final String htmlContent;
  final Function(String) onHtmlChanged;
  final bool isDemo;

  const InlineEditableHtmlPreview({
    super.key,
    required this.htmlContent,
    required this.onHtmlChanged,
    this.isDemo = false,
  });

  @override
  State<InlineEditableHtmlPreview> createState() => _InlineEditableHtmlPreviewState();
}

class _InlineEditableHtmlPreviewState extends State<InlineEditableHtmlPreview> {
  late String _currentHtml;
  bool _showEditMode = false;

  @override
  void initState() {
    super.initState();
    _currentHtml = widget.htmlContent;
  }

  @override
  void didUpdateWidget(InlineEditableHtmlPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.htmlContent != oldWidget.htmlContent) {
      _currentHtml = widget.htmlContent;
    }
  }

  void _toggleEditMode() {
    setState(() {
      _showEditMode = !_showEditMode;
    });
  }

  void _updateHtml(String newHtml) {
    setState(() {
      _currentHtml = newHtml;
    });
    widget.onHtmlChanged(newHtml);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 編集モード切り替えボタン（デモモードでのみ表示）
        if (widget.isDemo)
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(
                  _showEditMode ? Icons.preview : Icons.edit,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _toggleEditMode,
                  child: Text(
                    _showEditMode ? 'プレビューモード' : 'テキスト編集モード',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                if (_showEditMode)
                  ElevatedButton.icon(
                    onPressed: () {
                      _toggleEditMode();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ 編集内容を保存しました'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('保存'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
          ),

        // コンテンツ表示/編集エリア
        Expanded(
          child: _showEditMode ? _buildEditMode() : _buildPreviewMode(),
        ),
      ],
    );
  }

  Widget _buildPreviewMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildHtmlPreview(),
        ),
      ),
    );
  }

  Widget _buildEditMode() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'HTMLを直接編集できます。変更は即座にプレビューに反映されます。',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: _currentHtml),
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'HTML編集',
                alignLabelWithHint: true,
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              onChanged: _updateHtml,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHtmlPreview() {
    // 簡易HTMLパーサー（基本的なタグのみサポート）
    return _parseBasicHtml(_currentHtml);
  }

  Widget _parseBasicHtml(String html) {
    // 非常に簡易的なHTMLパーサー
    final cleanHtml = html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return Text(
      cleanHtml.isEmpty ? 'コンテンツが生成されていません' : cleanHtml,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}