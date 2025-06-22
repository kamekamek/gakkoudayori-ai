import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/adk_chat_provider.dart';
import '../../../home/presentation/widgets/audio_waveform_widget.dart';
import '../../../home/presentation/widgets/advanced_audio_waveform_widget.dart';

/// ADKエージェントとのチャットウィジェット
class AdkChatWidget extends StatefulWidget {
  final String userId;
  final Function(String)? onHtmlGenerated;

  const AdkChatWidget({
    Key? key,
    required this.userId,
    this.onHtmlGenerated,
  }) : super(key: key);

  @override
  State<AdkChatWidget> createState() => _AdkChatWidgetState();
}

class _AdkChatWidgetState extends State<AdkChatWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // 文字起こし結果をテキストフィールドに反映
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdkChatProvider>();
      provider.addListener(_onProviderChanged);
    });
  }
  
  void _onProviderChanged() {
    final provider = context.read<AdkChatProvider>();
    if (provider.transcriptionResult != null && 
        provider.transcriptionResult!.isNotEmpty) {
      setState(() {
        _textController.text = provider.transcriptionResult!;
      });
    }
  }

  @override
  void dispose() {
    final provider = context.read<AdkChatProvider>();
    provider.removeListener(_onProviderChanged);
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdkChatProvider>(
      builder: (context, provider, _) {
          // HTMLが生成されたらコールバックを呼び出す
          if (provider.generatedHtml != null &&
              widget.onHtmlGenerated != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onHtmlGenerated!(provider.generatedHtml!);
            });
          }

          return Column(
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.school,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '学級通信AIアシスタント',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (provider.sessionId != null)
                      TextButton.icon(
                        onPressed: () => provider.clearSession(),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('新しい会話'),
                      ),
                  ],
                ),
              ),

              // メッセージ表示エリア
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.messages.length +
                      (provider.isProcessing ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.messages.length &&
                        provider.isProcessing) {
                      return _buildProcessingIndicator();
                    }

                    final message = provider.messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),

              // エラー表示
              if (provider.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => provider.clearError(),
                      ),
                    ],
                  ),
                ),

              // 音声録音中の表示（スタイリッシュ版）
              if (provider.isVoiceRecording)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.errorContainer.withOpacity(0.9),
                        Theme.of(context).colorScheme.errorContainer.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // アニメーション付きマイクアイコン
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                            ),
                            child: AnimatedMicIcon(
                              isRecording: provider.isVoiceRecording,
                              color: Theme.of(context).colorScheme.error,
                              size: 16,
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // メイン波形表示
                          Expanded(
                            flex: 3,
                            child: AdvancedAudioWaveformWidget(
                              audioLevel: provider.audioLevel,
                              isRecording: provider.isVoiceRecording,
                              color: Theme.of(context).colorScheme.error,
                              barCount: 20,
                              height: 20,
                              style: WaveformStyle.ripple, // おしゃれな波紋エフェクト
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // ステータステキストとドットアニメーション
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '録音中',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              RecordingDotsIndicator(
                                color: Theme.of(context).colorScheme.error,
                                size: 4,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 入力エリア
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        maxLines: null,
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
                        ),
                        onSubmitted: (_) {
                          debugPrint('[AdkChatWidget] onSubmitted triggered!');
                          _sendMessage(provider);
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // 音声入力ボタン（アニメーション付き）
                    Container(
                      decoration: BoxDecoration(
                        color: provider.isVoiceRecording
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => _handleVoiceRecordingToggle(provider),
                        icon: AnimatedMicIcon(
                          isRecording: provider.isVoiceRecording,
                          color: provider.isVoiceRecording
                              ? Theme.of(context).colorScheme.onError
                              : Theme.of(context).colorScheme.onPrimary,
                        ),
                        tooltip: provider.isVoiceRecording ? '録音停止' : '音声入力',
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // 送信ボタン
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.send,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        onPressed: () {
                          debugPrint('[AdkChatWidget] Send button PRESSED!');
                          _sendMessage(provider);
                        },
                        tooltip: '送信',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
  }

  Widget _buildMessageBubble(MutableChatMessage message) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.school, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey.shade400,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.school, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('考えています...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(AdkChatProvider provider) {
    final text = _textController.text.trim();
    debugPrint('[AdkChatWidget] _sendMessage called. Text: "$text"');

    if (text.isEmpty) {
      debugPrint('[AdkChatWidget] Text is empty, aborting.');
      return;
    }

    provider.sendMessage(text);
    debugPrint('[AdkChatWidget] provider.sendMessage called.');

    _textController.clear();
    _focusNode.requestFocus();

    // スクロールを最下部へ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _handleVoiceRecordingToggle(AdkChatProvider provider) async {
    debugPrint('🎤 [AdkChatWidget] Voice recording toggle pressed. Current state: ${provider.isVoiceRecording}');
    
    if (provider.isVoiceRecording) {
      // 録音停止
      debugPrint('⏹️ [AdkChatWidget] Stopping voice recording...');
      await provider.stopVoiceRecording();
    } else {
      // 録音開始
      debugPrint('🎙️ [AdkChatWidget] Starting voice recording...');
      final success = await provider.startVoiceRecording();
      debugPrint('📊 [AdkChatWidget] Voice recording start result: $success');
      
      if (!success) {
        debugPrint('❌ [AdkChatWidget] Voice recording failed to start');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('音声録音を開始できませんでした。マイクのアクセス許可を確認してください。'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        debugPrint('✅ [AdkChatWidget] Voice recording started successfully');
      }
    }
  }
}
