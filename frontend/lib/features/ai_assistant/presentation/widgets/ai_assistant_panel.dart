import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../editor/providers/quill_editor_provider.dart';

/// AI補助パネル - 折りたたみ可能なAI機能UI
class AIAssistantPanel extends StatelessWidget {
  /// アニメーション持続時間
  static const Duration _animationDuration = Duration(milliseconds: 300);
  
  /// 展開時のパネル高さ
  static const double _expandedHeight = 150.0;
  
  /// パネル内のパディング
  static const EdgeInsets _panelPadding = EdgeInsets.all(16);
  
  /// ヘッダーのパディング
  static const EdgeInsets _headerPadding = EdgeInsets.symmetric(vertical: 12, horizontal: 16);

  const AIAssistantPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<QuillEditorProvider>(
      builder: (context, provider, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー（常に表示）
            _buildHeader(context, provider),
            
            // 展開可能コンテンツ
            AnimatedContainer(
              duration: _animationDuration,
              curve: Curves.easeInOut,
              height: provider.isAiAssistVisible ? _expandedHeight : 0,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              child: provider.isAiAssistVisible
                  ? _buildPanelContent(context, provider)
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  /// ヘッダー部分（タップで展開/折りたたみ）
  Widget _buildHeader(BuildContext context, QuillEditorProvider provider) {
    return InkWell(
      onTap: () {
        if (provider.isAiAssistVisible) {
          provider.hideAiAssist();
        } else {
          provider.showAiAssist(selectedText: '', cursorPosition: 0);
        }
      },
      child: Container(
        padding: _headerPadding,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.smart_toy, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'AI補助',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: provider.isAiAssistVisible ? 0.5 : 0,
              duration: _animationDuration,
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// パネルコンテンツ部分（展開時に表示）
  Widget _buildPanelContent(BuildContext context, QuillEditorProvider provider) {
    return Container(
      key: const Key('ai_panel_content'),
      padding: _panelPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // プレースホルダーコンテンツ
          // 実際のAI機能ボタンやカスタム入力は次のタスクで実装
          _buildPlaceholderContent(),

          // エラーメッセージ表示
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 8),
            _buildErrorMessage(provider),
          ],
        ],
      ),
    );
  }

  /// プレースホルダーコンテンツ（開発中表示）
  Widget _buildPlaceholderContent() {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: const Center(
        child: Text(
          '📎 AI機能はここに実装予定',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// エラーメッセージ表示ウィジェット
  Widget _buildErrorMessage(QuillEditorProvider provider) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, 
               color: Colors.red.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: provider.clearError,
            icon: Icon(Icons.close, 
                       color: Colors.red.shade600, size: 16),
          ),
        ],
      ),
    );
  }
}