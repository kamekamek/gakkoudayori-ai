import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../ai_assistant/providers/chat_provider.dart';
import '../../../editor/presentation/widgets/image_upload_widget.dart';
import 'chat_message_bubble.dart';
import 'chat_input_area.dart';

/// チャットインターフェース（左側パネル）
class ChatInterface extends StatefulWidget {
  const ChatInterface({super.key});

  @override
  State<ChatInterface> createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.smart_toy,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AIアシスタント',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 学級通信生成ボタン
                  ElevatedButton.icon(
                    onPressed: chatProvider.messages.where((m) => m.isUser).isNotEmpty && !chatProvider.isAiTyping
                        ? () => chatProvider.generateNewsletter()
                        : null,
                    icon: const Icon(Icons.article, size: 18),
                    label: const Text('生成', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(80, 36),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // チャットクリアボタン
                  IconButton(
                    onPressed: () => _showClearChatDialog(),
                    icon: const Icon(Icons.refresh),
                    tooltip: 'チャットをクリア',
                  ),
                ],
              ),
            ),

            // チャットメッセージ一覧
            Expanded(
              child: chatProvider.messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: chatProvider.messages.length,
                      itemBuilder: (context, index) {
                        final message = chatProvider.messages[index];
                        return ChatMessageBubble(
                          message: message,
                          onSuggestionTapped: (suggestion) {
                            chatProvider.sendSuggestion(suggestion);
                            _scrollToBottom();
                          },
                        );
                      },
                    ),
            ),

            // AIタイピング中インジケータ
            if (chatProvider.isAiTyping)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AIが返答を考えています...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

            // 入力エリア
            ChatInputArea(
              onMessageSent: (message) {
                chatProvider.sendMessage(message);
                _scrollToBottom();
              },
              isVoiceRecording: chatProvider.isVoiceRecording,
              onVoiceRecordingToggle: () => _handleVoiceRecordingToggle(chatProvider),
              onImageUpload: () => _showImageUploadDialog(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'AIとの会話を始めましょう',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '学級通信について何でもお聞かせください',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleVoiceRecordingToggle(ChatProvider chatProvider) async {
    if (chatProvider.isVoiceRecording) {
      // 録音停止
      await chatProvider.stopVoiceRecording();
    } else {
      // 録音開始
      final success = await chatProvider.startVoiceRecording();
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('音声録音を開始できませんでした。マイクのアクセス許可を確認してください。'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('チャットをクリア'),
        content: const Text('チャットの履歴をクリアしますか？この操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ChatProvider>().clearChat();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('クリア'),
          ),
        ],
      ),
    );
  }

  void _showImageUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 600,
          height: 500,
          child: Column(
            children: [
              // ダイアログヘッダー
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '画像アップロード',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: '閉じる',
                    ),
                  ],
                ),
              ),
              
              // 画像アップロードウィジェット
              Expanded(
                child: ImageUploadWidget(
                  showHeader: false,
                  onImagesChanged: () {
                    // 画像が変更されたときの処理
                    // 必要に応じてチャットにメッセージを追加
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}