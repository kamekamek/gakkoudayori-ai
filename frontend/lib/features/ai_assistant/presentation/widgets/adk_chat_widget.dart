import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/adk_chat_provider.dart';
import '../../../home/presentation/widgets/audio_waveform_widget.dart';
import '../../../home/presentation/widgets/advanced_audio_waveform_widget.dart';
import '../../../editor/presentation/widgets/image_upload_widget.dart';
import '../../../editor/providers/image_provider.dart';
import '../../../../core/models/chat_message.dart';

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
              // ヘッダー（デザインモックアップ準拠）
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2c5aa0), // プライマリブルー
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '💬 AI アシスタント',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2c5aa0),
                      ),
                    ),
                    const Spacer(),
                    if (provider.sessionId != null)
                      TextButton.icon(
                        onPressed: () => provider.clearSession(),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('🔄', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
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
                              color: Colors.white,
                              barCount: 20,
                              height: 32,
                              style: WaveformStyle.ripple, // 波紋エフェクト
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

              // 入力エリア（デザインモックアップ準拠）
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'メッセージを入力...',
                            hintStyle: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF424242),
                          ),
                          onSubmitted: (_) {
                            debugPrint('[AdkChatWidget] onSubmitted triggered!');
                            _sendMessage(provider);
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // 画像アップロードボタン
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2c5aa0),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2c5aa0).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => _showImageUploadDialog(context),
                        icon: const Icon(
                          Icons.image,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: '画像アップロード',
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // 音声入力ボタン
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: provider.isVoiceRecording
                            ? const Color(0xFFFF6B35) // セカンダリオレンジ
                            : const Color(0xFF2c5aa0), // プライマリブルー
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (provider.isVoiceRecording
                                    ? const Color(0xFFFF6B35)
                                    : const Color(0xFF2c5aa0))
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => _handleVoiceRecordingToggle(provider),
                        icon: Icon(
                          provider.isVoiceRecording ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: provider.isVoiceRecording ? '🎤' : '🎤',
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // 送信ボタン
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2c5aa0),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2c5aa0).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
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
    final hasImages = message.content.contains('📷') && message.content.contains('画像を添付しました');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2c5aa0),
                shape: BoxShape.circle,
              ),
              child: const Text(
                '🤖',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF2c5aa0)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImages)
                    Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.image,
                            size: 16,
                            color: isUser ? Colors.white.withOpacity(0.8) : const Color(0xFF666666),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '画像添付',
                            style: TextStyle(
                              color: isUser ? Colors.white.withOpacity(0.8) : const Color(0xFF666666),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF424242),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '👨‍🏫',
                style: TextStyle(fontSize: 16),
              ),
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

  void _showImageUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 600,
          height: 500,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('画像アップロード'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: ChangeNotifierProvider(
              create: (context) => ImageManagementProvider(),
              child: Consumer<ImageManagementProvider>(
                builder: (context, imageProvider, child) {
                  return Column(
                    children: [
                      Expanded(
                        child: ImageUploadWidget(
                          showHeader: false,
                          maxImages: 5,
                          onImagesChanged: () {
                            // 画像が変更されたときの処理
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('キャンセル'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: imageProvider.hasImages
                                  ? () => _addImagesToChat(context, imageProvider)
                                  : null,
                              icon: const Icon(Icons.add_photo_alternate),
                              label: Text('チャットに追加 (${imageProvider.imageCount})'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2c5aa0),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addImagesToChat(BuildContext context, ImageManagementProvider imageProvider) {
    final provider = context.read<AdkChatProvider>();
    
    // 画像情報をチャットに追加
    final imageDescriptions = imageProvider.uploadedImages
        .map((img) => '📷 ${img.name} (${img.sizeDisplay})')
        .join('\n');
    
    // テキストフィールドに画像情報を追加
    final currentText = _textController.text;
    final newText = currentText.isEmpty 
        ? '画像を添付しました:\n$imageDescriptions'
        : '$currentText\n\n画像を添付しました:\n$imageDescriptions';
    
    _textController.text = newText;
    
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📷 ${imageProvider.imageCount}枚の画像をチャットに追加しました'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
