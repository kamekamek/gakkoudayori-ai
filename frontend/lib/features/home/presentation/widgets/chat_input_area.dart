import 'package:flutter/material.dart';
import 'audio_waveform_widget.dart';

/// チャット入力エリア
class ChatInputArea extends StatefulWidget {
  final Function(String) onMessageSent;
  final bool isVoiceRecording;
  final VoidCallback? onVoiceRecordingToggle;
  final VoidCallback? onImageUpload;
  final String? transcriptionResult;
  final double audioLevel;

  const ChatInputArea({
    super.key,
    required this.onMessageSent,
    required this.isVoiceRecording,
    this.onVoiceRecordingToggle,
    this.onImageUpload,
    this.transcriptionResult,
    this.audioLevel = 0.0,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void didUpdateWidget(ChatInputArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 文字起こし結果が更新された場合、テキストフィールドに設定
    if (widget.transcriptionResult != null && 
        widget.transcriptionResult != oldWidget.transcriptionResult &&
        widget.transcriptionResult!.isNotEmpty) {
      _controller.text = widget.transcriptionResult!;
      setState(() {
        _isComposing = widget.transcriptionResult!.trim().isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 音声録音中の表示（波形付き）
          if (widget.isVoiceRecording)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AnimatedMicIcon(
                        isRecording: widget.isVoiceRecording,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '🎤 録音中... タップで停止',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AudioWaveformWidget(
                    audioLevel: widget.audioLevel,
                    isRecording: widget.isVoiceRecording,
                    color: Theme.of(context).colorScheme.error,
                    barCount: 7,
                    height: 30,
                  ),
                ],
              ),
            ),

          // 入力エリア
          Row(
            children: [
              // テキスト入力フィールド
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  onChanged: (text) {
                    setState(() {
                      _isComposing = text.trim().isNotEmpty;
                    });
                  },
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      _sendMessage();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'メッセージを入力...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    suffixIcon: _isComposing
                        ? IconButton(
                            onPressed: _sendMessage,
                            icon: Icon(
                              Icons.send,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            tooltip: '送信',
                          )
                        : null,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 画像アップロードボタン
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: widget.onImageUpload,
                  icon: Icon(
                    Icons.photo_camera,
                    color: Theme.of(context).colorScheme.onTertiary,
                  ),
                  tooltip: '画像追加',
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 音声入力ボタン
              Container(
                decoration: BoxDecoration(
                  color: widget.isVoiceRecording
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _toggleVoiceRecording,
                  icon: Icon(
                    widget.isVoiceRecording ? Icons.stop : Icons.mic,
                    color: widget.isVoiceRecording
                        ? Theme.of(context).colorScheme.onError
                        : Theme.of(context).colorScheme.onPrimary,
                  ),
                  tooltip: widget.isVoiceRecording ? '録音停止' : '音声入力',
                ),
              ),
            ],
          ),
          
          // 使い方のヒント
          if (!_isComposing && !widget.isVoiceRecording)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '💡 ヒント: 行事の様子や子どもたちの頑張り、保護者への連絡事項などを教えてください',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onMessageSent(text);
      _controller.clear();
      setState(() {
        _isComposing = false;
      });
    }
  }

  void _toggleVoiceRecording() {
    widget.onVoiceRecordingToggle?.call();
  }
}