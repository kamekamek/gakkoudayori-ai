import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../editor/providers/quill_editor_provider.dart';
import '../../../editor/presentation/widgets/quill_editor_widget.dart';
import '../../../editor/presentation/widgets/preview_pane_widget.dart';
import '../../../editor/presentation/widgets/tone_selector_widget.dart';
import '../../../ai_assistant/presentation/widgets/ai_functions_grid.dart';
import '../../../ai_assistant/presentation/widgets/ai_function_button.dart';

/// 画像フロー対応の強化エディタレイアウト
///
/// 3カラム構成：
/// - 左：音声入力 + AI機能パネル
/// - 中央：メインエディタ（タイトル + 本文）
/// - 右：プレビュー（Web/PDF切り替え）
class EnhancedEditorLayout extends StatefulWidget {
  const EnhancedEditorLayout({super.key});

  @override
  State<EnhancedEditorLayout> createState() => _EnhancedEditorLayoutState();
}

class _EnhancedEditorLayoutState extends State<EnhancedEditorLayout> {
  final TextEditingController _titleController = TextEditingController();
  bool _isVoiceRecording = false;
  String _transcribedText = '';

  @override
  void initState() {
    super.initState();
    _titleController.text = '学級通信のタイトルを入力してください';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('学級通信エディタ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDocument,
            tooltip: '保存',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: '設定',
          ),
        ],
      ),
      body: Row(
        children: [
          // 左パネル：音声入力 + AI機能
          Container(
            width: 320,
            color: Colors.white,
            child: Column(
              children: [
                // 音声入力セクション
                _buildVoiceInputSection(),

                const Divider(height: 1),

                // リアルタイム字幕表示
                if (_transcribedText.isNotEmpty) _buildTranscriptionPanel(),

                // クイックコマンド
                _buildQuickCommandsSection(),

                const Divider(height: 1),

                // AI機能グリッド
                Expanded(
                  child: _buildAIFunctionsSection(),
                ),
              ],
            ),
          ),

          // 中央パネル：メインエディタ
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // タイトル入力
                  _buildTitleSection(),

                  const SizedBox(height: 16),

                  // テイスト選択
                  const ToneSelectorWidget(),

                  const SizedBox(height: 16),

                  // メインエディタ
                  Expanded(
                    child: _buildMainEditor(),
                  ),

                  // ツールバー
                  _buildBottomToolbar(),
                ],
              ),
            ),
          ),

          // 右パネル：プレビュー
          Container(
            width: 400,
            color: Colors.white,
            child: _buildPreviewSection(),
          ),
        ],
      ),
    );
  }

  /// 音声入力セクション
  Widget _buildVoiceInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 音声入力ボタン
          GestureDetector(
            onTap: _toggleVoiceRecording,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isVoiceRecording
                      ? [Colors.red.shade300, Colors.red.shade600]
                      : [Colors.blue.shade300, Colors.blue.shade600],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isVoiceRecording ? Colors.red : Colors.blue)
                        .withValues(alpha: 0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isVoiceRecording ? Icons.stop : Icons.mic,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            _isVoiceRecording ? '録音中...' : 'タップして録音開始',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (_isVoiceRecording) ...[
            const SizedBox(height: 12),
            // 録音波形表示（模擬）
            Container(
              height: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(8, (index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200 + (index * 50)),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 4,
                    height: 10 + (index % 3 * 10).toDouble(),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 転写テキスト表示パネル
  Widget _buildTranscriptionPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.transcribe, size: 16, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                'リアルタイム字幕',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _transcribedText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addTranscriptionToEditor,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('エディタに追加'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _improveTranscription,
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: const Text('AI改善'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// クイックコマンドセクション
  Widget _buildQuickCommandsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'クイックコマンド',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickCommandButton('今日の出来事', Icons.event, () {}),
              _buildQuickCommandButton('連絡事項', Icons.announcement, () {}),
              _buildQuickCommandButton('学習内容', Icons.school, () {}),
              _buildQuickCommandButton('お知らせ', Icons.info, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCommandButton(
      String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.blue.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AI機能セクション
  Widget _buildAIFunctionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: AIFunctionsGrid(
        onFunctionPressed: (AIFunctionType functionType) {
          // AI機能実行の処理
          _executeAIFunction(functionType);
        },
      ),
    );
  }

  /// タイトルセクション
  Widget _buildTitleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'タイトル',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '学級通信のタイトルを入力してください',
            ),
          ),
        ],
      ),
    );
  }

  /// メインエディタ
  Widget _buildMainEditor() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // エディタヘッダー
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '本文',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                Text(
                  '0文字',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Quillエディタ
          Expanded(
            child: QuillEditorWidget(
              onContentChanged: (content) {
                // 文字数更新などの処理
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 底部ツールバー
  Widget _buildBottomToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildToolbarButton('太字', Icons.format_bold, () {}),
          _buildToolbarButton('斜体', Icons.format_italic, () {}),
          _buildToolbarButton('下線', Icons.format_underlined, () {}),
          _buildToolbarButton('色', Icons.palette, () {}),
          _buildToolbarButton('見出し', Icons.title, () {}),
          const Spacer(),
          _buildToolbarButton('画像', Icons.image, () {}),
          _buildToolbarButton('表情', Icons.emoji_emotions, () {}),
          _buildToolbarButton('AI改善', Icons.auto_awesome, () {}),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// プレビューセクション
  Widget _buildPreviewSection() {
    return Column(
      children: [
        // プレビューヘッダー
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'プレビュー',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    _buildPreviewModeButton('Web', true),
                    _buildPreviewModeButton('PDF', false),
                  ],
                ),
              ),
            ],
          ),
        ),

        // プレビューコンテンツ
        Expanded(
          child: PreviewPaneWidget(
            htmlContent: '<h1>プレビュー</h1><p>ここにコンテンツが表示されます。</p>',
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewModeButton(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade500 : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
      ),
    );
  }

  // イベントハンドラー
  void _toggleVoiceRecording() {
    setState(() {
      _isVoiceRecording = !_isVoiceRecording;
      if (_isVoiceRecording) {
        _startVoiceRecording();
      } else {
        _stopVoiceRecording();
      }
    });
  }

  void _startVoiceRecording() {
    // 音声録音開始の実装
    // TODO: Web Audio API連携
  }

  void _stopVoiceRecording() {
    // 音声録音停止・転写開始の実装
    setState(() {
      _transcribedText =
          '今日は運動会の練習をしました。子どもたちはとても頑張っていて、リレーの練習では白熱した競争が繰り広げられました。本番までもう少しです。みんなで力を合わせて素晴らしい運動会にしましょう。';
    });
  }

  void _addTranscriptionToEditor() {
    // エディタに転写テキストを追加
    final provider = Provider.of<QuillEditorProvider>(context, listen: false);
    provider.insertTextAtPosition(_transcribedText);
    setState(() {
      _transcribedText = '';
    });
  }

  void _improveTranscription() {
    // AI改善の実装
  }

  void _executeAIFunction(AIFunctionType functionType) {
    // AI機能実行の実装
    switch (functionType) {
      case AIFunctionType.addGreeting:
        // 季節挨拶追加
        break;
      case AIFunctionType.addSchedule:
        // 予定追加
        break;
      case AIFunctionType.rewrite:
        // 文章リライト
        break;
      case AIFunctionType.generateHeading:
        // 見出し生成
        break;
      case AIFunctionType.summarize:
        // 要約
        break;
      case AIFunctionType.expand:
        // 展開
        break;
    }
  }

  void _saveDocument() {
    // ドキュメント保存の実装
  }

  void _showSettings() {
    // 設定画面表示の実装
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
