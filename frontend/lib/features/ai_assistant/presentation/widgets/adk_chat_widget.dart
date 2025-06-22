import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../services/adk_agent_service.dart';
import '../../providers/adk_chat_provider.dart';

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
  void dispose() {
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
    return ChangeNotifierProvider(
      create: (_) => AdkChatProvider(
        adkService: AdkAgentService(),
        userId: widget.userId,
      ),
      child: Consumer<AdkChatProvider>(
        builder: (context, provider, _) {
          // HTMLが生成されたらコールバックを呼び出す
          if (provider.generatedHtml != null && widget.onHtmlGenerated != null) {
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
                        decoration: InputDecoration(
                          hintText: provider.sessionId == null 
                              ? '「学級通信を作りたい」と入力してください'
                              : 'メッセージを入力...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        enabled: !provider.isProcessing,
                        onSubmitted: (_) => _sendMessage(provider),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: provider.isProcessing 
                          ? null 
                          : () => _sendMessage(provider),
                      icon: Icon(
                        Icons.send,
                        color: provider.isProcessing 
                            ? Colors.grey 
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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
    if (text.isEmpty) return;

    provider.sendMessage(text);
    _textController.clear();
    _focusNode.requestFocus();
    
    // スクロールを最下部へ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
}