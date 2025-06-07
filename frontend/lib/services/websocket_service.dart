import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

/// WebSocketチャット機能のクライアントサービス
class WebSocketService {
  static const String _baseUrl =
      kDebugMode ? 'ws://localhost:8000' : 'wss://your-production-domain.com';

  IO.Socket? _socket;
  String? _currentDocumentId;
  String? _currentUserId;
  String? _authToken;

  // イベントストリーム
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _aiSuggestionController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _userActivityController =
      StreamController<Map<String, dynamic>>.broadcast();

  // ゲッター
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get aiSuggestionStream =>
      _aiSuggestionController.stream;
  Stream<Map<String, dynamic>> get userActivityStream =>
      _userActivityController.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// WebSocket接続を初期化
  Future<void> connect({
    required String documentId,
    required String userId,
    required String authToken,
  }) async {
    try {
      _currentDocumentId = documentId;
      _currentUserId = userId;
      _authToken = authToken;

      // 既存の接続があれば切断
      await disconnect();

      // WebSocket接続を作成
      _socket = IO.io(
          '$_baseUrl/api/ws/chat/$documentId',
          IO.OptionBuilder()
              .setTransports(['websocket'])
              .setQuery({'token': authToken})
              .enableAutoConnect()
              .build());

      // イベントリスナーを設定
      _setupEventListeners();

      // 接続を開始
      _socket!.connect();

      debugPrint('WebSocket connecting to document: $documentId');
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      rethrow;
    }
  }

  /// WebSocket接続を切断
  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _currentDocumentId = null;
    _currentUserId = null;
    _authToken = null;

    debugPrint('WebSocket disconnected');
  }

  /// イベントリスナーを設定
  void _setupEventListeners() {
    if (_socket == null) return;

    // 接続成功
    _socket!.on('connect', (data) {
      debugPrint('WebSocket connected successfully');
    });

    // 接続エラー
    _socket!.on('connect_error', (error) {
      debugPrint('WebSocket connection error: $error');
    });

    // 切断
    _socket!.on('disconnect', (reason) {
      debugPrint('WebSocket disconnected: $reason');
    });

    // チャットメッセージ受信
    _socket!.on('chat_message', (data) {
      _messageController.add(Map<String, dynamic>.from(data));
    });

    // AI提案受信
    _socket!.on('ai_suggestion', (data) {
      _aiSuggestionController.add(Map<String, dynamic>.from(data));
    });

    // ユーザー参加/離脱
    _socket!.on('user_joined', (data) {
      _userActivityController
          .add({'type': 'user_joined', ...Map<String, dynamic>.from(data)});
    });

    _socket!.on('user_left', (data) {
      _userActivityController
          .add({'type': 'user_left', ...Map<String, dynamic>.from(data)});
    });

    // タイピングインジケーター
    _socket!.on('typing_indicator', (data) {
      _userActivityController.add(
          {'type': 'typing_indicator', ...Map<String, dynamic>.from(data)});
    });

    // コンテンツ更新
    _socket!.on('content_updated', (data) {
      _messageController
          .add({'type': 'content_updated', ...Map<String, dynamic>.from(data)});
    });

    // 編集提案の結果
    _socket!.on('suggestion_applied', (data) {
      _messageController.add(
          {'type': 'suggestion_applied', ...Map<String, dynamic>.from(data)});
    });

    _socket!.on('suggestion_rejected', (data) {
      _messageController.add(
          {'type': 'suggestion_rejected', ...Map<String, dynamic>.from(data)});
    });

    // エラー
    _socket!.on('error', (error) {
      debugPrint('WebSocket error: $error');
      _messageController.add({
        'type': 'error',
        'message': error.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  /// チャットメッセージを送信
  void sendChatMessage(String content) {
    if (_socket?.connected != true) {
      debugPrint('WebSocket not connected');
      return;
    }

    final message = {
      'type': 'chat_message',
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _socket!.emit('message', message);
  }

  /// コンテンツ更新を送信
  void sendContentUpdate(String content) {
    if (_socket?.connected != true) {
      debugPrint('WebSocket not connected');
      return;
    }

    final message = {
      'type': 'content_update',
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _socket!.emit('message', message);
  }

  /// 編集リクエストを送信
  void sendEditRequest({
    required String editType, // 'accept', 'reject', 'modify'
    required String suggestionId,
    String? modifiedContent,
  }) {
    if (_socket?.connected != true) {
      debugPrint('WebSocket not connected');
      return;
    }

    final message = {
      'type': 'edit_request',
      'edit_type': editType,
      'suggestion_id': suggestionId,
      if (modifiedContent != null) 'modified_content': modifiedContent,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _socket!.emit('message', message);
  }

  /// タイピングインジケーターを送信
  void sendTypingIndicator(bool isTyping) {
    if (_socket?.connected != true) {
      debugPrint('WebSocket not connected');
      return;
    }

    final message = {
      'type': 'typing',
      'is_typing': isTyping,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _socket!.emit('message', message);
  }

  /// リソースを解放
  void dispose() {
    disconnect();
    _messageController.close();
    _aiSuggestionController.close();
    _userActivityController.close();
  }
}

/// WebSocketサービスのシングルトンインスタンス
final webSocketService = WebSocketService();
