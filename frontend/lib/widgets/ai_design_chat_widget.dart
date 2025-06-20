import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'adk_agent_dashboard.dart'; // NewsletterStyle

/// AIデザインチャットウィジェット
/// 
/// 完成した学級通信に対して、AIと対話しながらリアルタイムで
/// デザイン修正を行うためのインターフェース
class AIDesignChatWidget extends StatefulWidget {
  final String initialHtml;
  final NewsletterStyle style;
  final Function(String modifiedHtml)? onHtmlModified;
  final Function(DesignChatMessage message)? onMessageSent;
  final bool isVoiceEnabled;

  const AIDesignChatWidget({
    Key? key,
    required this.initialHtml,
    required this.style,
    this.onHtmlModified,
    this.onMessageSent,
    this.isVoiceEnabled = true,
  }) : super(key: key);

  @override
  State<AIDesignChatWidget> createState() => _AIDesignChatWidgetState();
}

class _AIDesignChatWidgetState extends State<AIDesignChatWidget>
    with TickerProviderStateMixin {
  late TextEditingController _messageController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  List<DesignChatMessage> _chatHistory = [];
  String _currentHtml = '';
  bool _isListening = false;
  bool _isProcessing = false;
  List<DesignModification> _modificationHistory = [];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _currentHtml = widget.initialHtml;
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeChat() {
    setState(() {
      _chatHistory.add(DesignChatMessage(
        id: 'init',
        sender: MessageSender.ai,
        content: '🎉 学級通信が完成しました！\n\n何か修正したい点はありますか？\n\n例：\n• "もう少し明るい色にして"\n• "写真を大きくして"\n• "見出しを中央揃えにして"',
        timestamp: DateTime.now(),
        modificationType: null,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                // チャットエリア
                Expanded(
                  flex: 1,
                  child: _buildChatArea(),
                ),
                const VerticalDivider(width: 1),
                // プレビューエリア
                Expanded(
                  flex: 1,
                  child: _buildPreviewArea(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.style == NewsletterStyle.classic 
            ? Colors.blue.shade50 
            : Colors.orange.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: widget.style == NewsletterStyle.classic 
                ? Colors.blue.shade700 
                : Colors.orange.shade700,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🤖 AIデザインアシスタント',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'AIと対話して理想の学級通信に仕上げましょう',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (_isProcessing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.style == NewsletterStyle.classic 
                    ? Colors.blue.shade700 
                    : Colors.orange.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '修正中...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            '準備完了',
            style: TextStyle(
              fontSize: 11,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Column(
      children: [
        // チャット履歴
        Expanded(child: _buildChatHistory()),
        // クイック修正オプション
        _buildQuickModificationPanel(),
        // 入力エリア
        _buildInputArea(),
      ],
    );
  }

  Widget _buildChatHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: _chatHistory.length,
        itemBuilder: (context, index) {
          return _buildChatBubble(_chatHistory[index]);
        },
      ),
    );
  }

  Widget _buildChatBubble(DesignChatMessage message) {
    final isAI = message.sender == MessageSender.ai;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[
            _buildAvatar(true),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAI ? Colors.grey.shade100 : (
                  widget.style == NewsletterStyle.classic 
                      ? Colors.blue.shade50 
                      : Colors.orange.shade50
                ),
                borderRadius: BorderRadius.circular(12),
                border: isAI ? null : Border.all(
                  color: widget.style == NewsletterStyle.classic 
                      ? Colors.blue.shade200 
                      : Colors.orange.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isAI ? Colors.grey.shade800 : Colors.grey.shade900,
                    ),
                  ),
                  if (message.modificationType != null) ...[
                    const SizedBox(height: 8),
                    _buildModificationChip(message.modificationType!),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isAI) ...[
            const SizedBox(width: 12),
            _buildAvatar(false),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isAI) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isAI ? Colors.grey.shade300 : (
          widget.style == NewsletterStyle.classic 
              ? Colors.blue.shade100 
              : Colors.orange.shade100
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isAI ? Icons.smart_toy : Icons.person,
        size: 18,
        color: isAI ? Colors.grey.shade600 : (
          widget.style == NewsletterStyle.classic 
              ? Colors.blue.shade700 
              : Colors.orange.shade700
        ),
      ),
    );
  }

  Widget _buildModificationChip(DesignModificationType type) {
    Color color;
    IconData icon;
    String text;
    
    switch (type) {
      case DesignModificationType.color:
        color = Colors.purple;
        icon = Icons.palette;
        text = '色調修正';
        break;
      case DesignModificationType.layout:
        color = Colors.green;
        icon = Icons.view_column;
        text = 'レイアウト';
        break;
      case DesignModificationType.content:
        color = Colors.blue;
        icon = Icons.edit;
        text = '内容修正';
        break;
      case DesignModificationType.font:
        color = Colors.orange;
        icon = Icons.font_download;
        text = 'フォント';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickModificationPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔧 クイック修正',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildQuickButton('🎨 明るく', () => _sendQuickModification('明るい色にして')),
              _buildQuickButton('📸 画像大', () => _sendQuickModification('写真を大きくして')),
              _buildQuickButton('📝 文字大', () => _sendQuickModification('文字を大きくして')),
              _buildQuickButton('📐 2列', () => _sendQuickModification('2列レイアウトにして')),
              _buildQuickButton('🎯 中央', () => _sendQuickModification('見出しを中央揃えにして')),
              _buildQuickButton('↩️ 元に戻す', () => _undoLastModification()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String text, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 音声入力ボタン
          if (widget.isVoiceEnabled)
            GestureDetector(
              onTap: _toggleVoiceInput,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.red : (
                          widget.style == NewsletterStyle.classic 
                              ? Colors.blue.shade100 
                              : Colors.orange.shade100
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.white : (
                          widget.style == NewsletterStyle.classic 
                              ? Colors.blue.shade700 
                              : Colors.orange.shade700
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (widget.isVoiceEnabled) const SizedBox(width: 12),
          
          // テキスト入力
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: '修正したい内容を入力...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _sendTextMessage(),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // 送信ボタン
          IconButton(
            onPressed: _messageController.text.isNotEmpty ? _sendTextMessage : null,
            icon: Icon(
              Icons.send,
              color: widget.style == NewsletterStyle.classic 
                  ? Colors.blue.shade700 
                  : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'リアルタイムプレビュー',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '修正回数: ${_modificationHistory.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: HtmlWidget(
                  _currentHtml,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleVoiceInput() {
    setState(() {
      _isListening = !_isListening;
    });
    
    if (_isListening) {
      _pulseController.repeat(reverse: true);
      // 音声認識開始
      // TODO: 音声認識サービス統合
    } else {
      _pulseController.stop();
      _pulseController.reset();
      // 音声認識停止
    }
  }

  void _sendTextMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    _sendMessage(message);
    _messageController.clear();
  }

  void _sendQuickModification(String modification) {
    _sendMessage(modification);
  }

  void _sendMessage(String content) {
    // ユーザーメッセージを追加
    setState(() {
      _chatHistory.add(DesignChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.user,
        content: content,
        timestamp: DateTime.now(),
      ));
      _isProcessing = true;
    });
    
    // AI処理をシミュレート
    _processDesignModification(content);
  }

  void _processDesignModification(String userRequest) {
    // TODO: 実際のAI処理統合
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isProcessing = false;
        
        // AI応答を追加
        _chatHistory.add(DesignChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: MessageSender.ai,
          content: _generateAIResponse(userRequest),
          timestamp: DateTime.now(),
          modificationType: _getModificationType(userRequest),
        ));
        
        // HTML修正をシミュレート
        _currentHtml = _applyModification(_currentHtml, userRequest);
        
        // 修正履歴に追加
        _modificationHistory.add(DesignModification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userRequest: userRequest,
          previousHtml: _currentHtml,
          modifiedHtml: _currentHtml,
          timestamp: DateTime.now(),
        ));
      });
      
      widget.onHtmlModified?.call(_currentHtml);
    });
  }

  String _generateAIResponse(String userRequest) {
    if (userRequest.contains('明るい') || userRequest.contains('色')) {
      return '承知しました！カラーパレットを明るく調整しました。季節感のある色調に変更しています。いかがでしょうか？';
    } else if (userRequest.contains('大きく') || userRequest.contains('画像') || userRequest.contains('写真')) {
      return '写真のサイズを拡大しました。より目立つように配置も調整しています。';
    } else if (userRequest.contains('文字') || userRequest.contains('フォント')) {
      return 'フォントサイズを調整しました。読みやすさを保ちながら見やすくしています。';
    } else if (userRequest.contains('レイアウト') || userRequest.contains('列')) {
      return 'レイアウトを調整しました。情報を整理して見やすく配置しています。';
    } else {
      return 'ご要望に応じて修正を行いました。他にも調整したい点があればお聞かせください。';
    }
  }

  DesignModificationType? _getModificationType(String userRequest) {
    if (userRequest.contains('色') || userRequest.contains('明るい') || userRequest.contains('暗い')) {
      return DesignModificationType.color;
    } else if (userRequest.contains('レイアウト') || userRequest.contains('列') || userRequest.contains('配置')) {
      return DesignModificationType.layout;
    } else if (userRequest.contains('フォント') || userRequest.contains('文字')) {
      return DesignModificationType.font;
    } else if (userRequest.contains('内容') || userRequest.contains('文章')) {
      return DesignModificationType.content;
    }
    return null;
  }

  String _applyModification(String currentHtml, String userRequest) {
    // TODO: 実際の修正処理を実装
    // 現在はシミュレーション
    return currentHtml;
  }

  void _undoLastModification() {
    if (_modificationHistory.isEmpty) return;
    
    setState(() {
      _modificationHistory.removeLast();
      if (_modificationHistory.isNotEmpty) {
        _currentHtml = _modificationHistory.last.modifiedHtml;
      } else {
        _currentHtml = widget.initialHtml;
      }
      
      _chatHistory.add(DesignChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.ai,
        content: '前の修正を取り消しました。',
        timestamp: DateTime.now(),
      ));
    });
    
    widget.onHtmlModified?.call(_currentHtml);
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

/// デザインチャットメッセージ
class DesignChatMessage {
  final String id;
  final MessageSender sender;
  final String content;
  final DateTime timestamp;
  final DesignModificationType? modificationType;

  DesignChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.modificationType,
  });
}

/// メッセージ送信者
enum MessageSender {
  user,
  ai,
}

/// デザイン修正タイプ
enum DesignModificationType {
  color,
  layout,
  font,
  content,
}

/// デザイン修正履歴
class DesignModification {
  final String id;
  final String userRequest;
  final String previousHtml;
  final String modifiedHtml;
  final DateTime timestamp;

  DesignModification({
    required this.id,
    required this.userRequest,
    required this.previousHtml,
    required this.modifiedHtml,
    required this.timestamp,
  });
}