import 'package:flutter/foundation.dart';
import '../../../services/adk_agent_service.dart';

/// ADKチャットの状態管理プロバイダー
class AdkChatProvider extends ChangeNotifier {
  final AdkAgentService _adkService;
  final String userId;

  // 状態
  final List<MutableChatMessage> _messages = [];
  String? _sessionId;
  bool _isProcessing = false;
  String? _error;
  String? _generatedHtml;

  // ゲッター
  List<MutableChatMessage> get messages => _messages;
  String? get sessionId => _sessionId;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String? get generatedHtml => _generatedHtml;

  AdkChatProvider({
    required AdkAgentService adkService,
    required this.userId,
  }) : _adkService = adkService;

  /// メッセージを送信
  Future<void> sendMessage(String message) async {
    if (_isProcessing) return;

    // ユーザーメッセージを追加
    _messages.add(MutableChatMessage(
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    ));
    
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // 学級通信作成のトリガーかチェック
      if (_shouldStartNewsletterGeneration(message)) {
        // 学級通信生成を開始
        final response = await _adkService.startNewsletterGeneration(
          initialRequest: message,
          userId: userId,
          sessionId: _sessionId,
        );

        _sessionId = response.sessionId;
        
        // レスポンスのメッセージを追加
        if (response.messages.isNotEmpty) {
          _messages.addAll(
            response.messages
              .where((m) => m.role != 'user')
              .map((m) => MutableChatMessage.fromChatMessage(m))
          );
        }

        // HTMLが生成されたら保存
        if (response.htmlContent != null) {
          _generatedHtml = response.htmlContent;
        }
      } else {
        // 通常のチャット
        final response = await _adkService.sendChatMessage(
          message: message,
          userId: userId,
          sessionId: _sessionId,
        );

        _sessionId = response.sessionId;
        
        // アシスタントのメッセージを追加
        _messages.add(MutableChatMessage(
          role: 'assistant',
          content: response.message,
          timestamp: DateTime.now(),
        ));

        // HTMLが生成されたら保存
        if (response.htmlOutput != null) {
          _generatedHtml = response.htmlOutput;
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending message: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// ストリーミングでメッセージを送信
  Future<void> sendMessageStreaming(String message) async {
    if (_isProcessing) return;

    // ユーザーメッセージを追加
    _messages.add(MutableChatMessage(
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    ));
    
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // アシスタントメッセージを準備
      final assistantMessage = MutableChatMessage(
        role: 'assistant',
        content: '',
        timestamp: DateTime.now(),
      );
      _messages.add(assistantMessage);

      // ストリーミング開始
      final stream = _adkService.streamChatSSE(
        message: message,
        userId: userId,
        sessionId: _sessionId,
      );

      await for (final event in stream) {
        _sessionId = event.sessionId;
        
        switch (event.type) {
          case 'message':
            // メッセージを追加していく
            assistantMessage.content += event.data;
            notifyListeners();
            break;
          case 'complete':
            // HTML生成完了
            _generatedHtml = event.data;
            notifyListeners();
            break;
          case 'error':
            _error = event.data;
            notifyListeners();
            break;
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error in streaming: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// セッションをクリア
  void clearSession() {
    _messages.clear();
    _sessionId = null;
    _generatedHtml = null;
    _error = null;
    notifyListeners();
  }

  /// エラーをクリア
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 学級通信生成を開始すべきかチェック
  bool _shouldStartNewsletterGeneration(String message) {
    final lowerMessage = message.toLowerCase();
    return lowerMessage.contains('学級通信') || 
           lowerMessage.contains('がっきゅうつうしん') ||
           lowerMessage.contains('おたより') ||
           lowerMessage.contains('newsletter');
  }

  @override
  void dispose() {
    _adkService.dispose();
    super.dispose();
  }
}

/// ミュータブルなチャットメッセージクラス
class MutableChatMessage {
  final String role;
  String content;
  final DateTime timestamp;

  MutableChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory MutableChatMessage.fromChatMessage(ChatMessage message) {
    return MutableChatMessage(
      role: message.role,
      content: message.content,
      timestamp: message.timestamp,
    );
  }
}