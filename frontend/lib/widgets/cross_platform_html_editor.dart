import 'package:flutter/material.dart';
import 'html_widget_preview.dart';

/// クロスプラットフォーム対応HTMLエディタ
/// 現在はWeb版のみ対応（HtmlWidgetPreview使用）
class CrossPlatformHtmlEditor extends StatefulWidget {
  final String htmlContent;
  final double height;
  final Function(String)? onContentChanged;
  final bool isEditable;

  const CrossPlatformHtmlEditor({
    super.key,
    required this.htmlContent,
    this.height = 500,
    this.onContentChanged,
    this.isEditable = false,
  });

  @override
  State<CrossPlatformHtmlEditor> createState() =>
      _CrossPlatformHtmlEditorState();
}

class _CrossPlatformHtmlEditorState extends State<CrossPlatformHtmlEditor> {
  String _currentHtml = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentHtml = widget.htmlContent;
    _isLoading = false;
  }

  @override
  void didUpdateWidget(CrossPlatformHtmlEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlContent != widget.htmlContent) {
      setState(() {
        _currentHtml = widget.htmlContent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Web版のみ対応
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: HtmlWidgetPreview(
        htmlContent: _currentHtml,
        height: widget.height,
      ),
    );
  }
}
