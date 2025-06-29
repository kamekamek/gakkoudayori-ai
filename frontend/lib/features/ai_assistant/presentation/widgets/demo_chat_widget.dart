import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/demo_chat_provider.dart';
import '../../../../services/demo_data_service.dart';

/// デモモード用のチャットウィジェット
class DemoChatWidget extends StatefulWidget {
  const DemoChatWidget({super.key});

  @override
  State<DemoChatWidget> createState() => _DemoChatWidgetState();
}

class _DemoChatWidgetState extends State<DemoChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // デモ開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DemoChatProvider>().startDemo();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Consumer<DemoChatProvider>(
      builder: (context, provider, child) {
        // メッセージが追加されたら自動スクロール
        if (provider.messages.isNotEmpty) {
          _scrollToBottom();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'AI アシスタント',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // メッセージリスト
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.messages.length + (provider.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.messages.length && provider.isLoading) {
                      return _buildLoadingMessage();
                    }

                    final message = provider.messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
              
              // 入力エリア
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Column(
                  children: [
                    // 入力フィールド
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'メッセージを入力...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (text) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // マイクボタン
                        GestureDetector(
                          onTap: () => provider.toggleRecording(),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: provider.isRecording 
                                  ? Colors.red 
                                  : Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              provider.isRecording 
                                  ? Icons.stop 
                                  : Icons.mic,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // 送信ボタン
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(DemoChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green.shade100,
              child: const Icon(
                Icons.smart_toy,
                size: 16,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? Colors.blue.shade500 
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isVoiceInput)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_voice,
                            size: 16,
                            color: message.isUser 
                                ? Colors.white.withOpacity(0.8)
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '音声入力',
                            style: TextStyle(
                              fontSize: 12,
                              color: message.isUser 
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser 
                          ? Colors.white 
                          : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: message.isUser 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.blue,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.green.shade100,
            child: const Icon(
              Icons.smart_toy,
              size: 16,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 8),
                Text('入力中...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      context.read<DemoChatProvider>().sendMessage(_controller.text);
      _controller.clear();
    }
  }
}