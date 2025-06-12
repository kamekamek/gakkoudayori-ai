import 'package:flutter/material.dart';

enum PreviewMode { desktop, mobile, print }

class PreviewPaneWidget extends StatefulWidget {
  final String htmlContent;
  final PreviewMode mode;
  final VoidCallback? onModeChanged;

  const PreviewPaneWidget({
    super.key,
    required this.htmlContent,
    this.mode = PreviewMode.desktop,
    this.onModeChanged,
  });

  @override
  State<PreviewPaneWidget> createState() => _PreviewPaneWidgetState();
}

class _PreviewPaneWidgetState extends State<PreviewPaneWidget> {
  PreviewMode _currentMode = PreviewMode.desktop;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;
  }

  void _changeMode(PreviewMode mode) {
    setState(() {
      _currentMode = mode;
    });
    widget.onModeChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // モード切り替えボタン
        Row(
          children: [
            _buildModeButton(PreviewMode.desktop, Icons.desktop_mac, 'デスクトップ'),
            _buildModeButton(PreviewMode.mobile, Icons.phone_android, 'モバイル'),
            _buildModeButton(PreviewMode.print, Icons.print, '印刷'),
          ],
        ),
        const SizedBox(height: 16),
        // プレビューコンテンツ
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: _buildPreviewContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton(PreviewMode mode, IconData icon, String label) {
    final isSelected = _currentMode == mode;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: () => _changeMode(mode),
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
          foregroundColor: isSelected ? Colors.white : null,
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    switch (_currentMode) {
      case PreviewMode.desktop:
        return _buildDesktopPreview();
      case PreviewMode.mobile:
        return _buildMobilePreview();
      case PreviewMode.print:
        return _buildPrintPreview();
    }
  }

  Widget _buildDesktopPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: _renderHtml(),
    );
  }

  Widget _buildMobilePreview() {
    return Container(
      width: 375, // iPhone幅に近似
      padding: const EdgeInsets.all(12),
      child: _renderHtml(),
    );
  }

  Widget _buildPrintPreview() {
    return Container(
      width: 595, // A4幅（72DPI基準）
      padding: const EdgeInsets.all(24),
      child: _renderHtml(),
    );
  }

  Widget _renderHtml() {
    // HTMLコンテンツを簡易的にTextで表示
    // 本来はHTMLレンダリングが必要
    return Text(
      widget.htmlContent.isNotEmpty
          ? widget.htmlContent.replaceAll(RegExp(r'<[^>]*>'), '') // HTMLタグ除去
          : 'プレビューするコンテンツがありません',
      style: const TextStyle(fontSize: 14),
    );
  }
}
