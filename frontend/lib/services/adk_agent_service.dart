import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

/// ADKエージェントとの通信を管理するサービス
class AdkAgentService {
  final String _baseUrl = AppConfig.apiBaseUrl;
  final http.Client _httpClient = http.Client();

  /// チャットメッセージをエージェントに送信
  Future<AdkChatResponse> sendChatMessage({
    required String message,
    required String userId,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/adk/chat');
      final response = await _httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'user_id': userId,
          'session_id': sessionId,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AdkChatResponse.fromJson(data);
      } else {
        throw Exception('Failed to send chat message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending chat message: $e');
    }
  }

  /// 学級通信の生成を開始
  Future<NewsletterGenerationResponse> startNewsletterGeneration({
    required String initialRequest,
    required String userId,
    String? sessionId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/adk/newsletter/generate');
      final response = await _httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'initial_request': initialRequest,
          'user_id': userId,
          'session_id': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NewsletterGenerationResponse.fromJson(data);
      } else {
        throw Exception('Failed to start newsletter generation: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error starting newsletter generation: $e');
    }
  }

  /// セッション情報を取得
  Future<SessionInfo> getSession(String sessionId) async {
    try {
      final url = Uri.parse('$_baseUrl/adk/sessions/$sessionId');
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SessionInfo.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Session not found');
      } else {
        throw Exception('Failed to get session: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting session: $e');
    }
  }

  /// セッションを削除
  Future<void> deleteSession(String sessionId) async {
    try {
      final url = Uri.parse('$_baseUrl/adk/sessions/$sessionId');
      final response = await _httpClient.delete(url);

      if (response.statusCode != 200) {
        throw Exception('Failed to delete session: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting session: $e');
    }
  }

  /// WebSocketを使用したストリーミングチャット
  Stream<AdkAgentEvent> streamChat({
    required String sessionId,
    required String userId,
  }) {
    final wsUrl = _baseUrl.replaceFirst('http', 'ws');
    final channel = WebSocketChannel.connect(
      Uri.parse('$wsUrl/adk/ws/$sessionId'),
    );

    final controller = StreamController<AdkAgentEvent>.broadcast();

    // WebSocketからのメッセージを処理
    channel.stream.listen(
      (data) {
        try {
          final json = jsonDecode(data);
          final event = AdkAgentEvent.fromJson(json);
          controller.add(event);
        } catch (e) {
          controller.addError('Error parsing WebSocket data: $e');
        }
      },
      onError: (error) {
        controller.addError('WebSocket error: $error');
      },
      onDone: () {
        controller.close();
      },
    );

    // メッセージ送信関数を返す
    return controller.stream;
  }

  /// WebSocketでメッセージを送信
  void sendWebSocketMessage(
    WebSocketChannel channel,
    String message,
    String userId,
  ) {
    channel.sink.add(jsonEncode({
      'message': message,
      'user_id': userId,
    }));
  }

  /// Server-Sent Eventsを使用したストリーミングチャット
  Stream<AdkStreamEvent> streamChatSSE({
    required String message,
    required String userId,
    String? sessionId,
  }) async* {
    try {
      final url = Uri.parse('$_baseUrl/adk/chat/stream');
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'message': message,
          'user_id': userId,
          'session_id': sessionId,
        });

      final response = await _httpClient.send(request);

      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data.trim().isNotEmpty) {
                try {
                  final json = jsonDecode(data);
                  yield AdkStreamEvent.fromJson(json);
                } catch (e) {
                  yield AdkStreamEvent(
                    sessionId: sessionId ?? '',
                    type: 'error',
                    data: 'Error parsing SSE data: $e',
                  );
                }
              }
            }
          }
        }
      } else {
        throw Exception('Failed to stream chat: ${response.statusCode}');
      }
    } catch (e) {
      yield AdkStreamEvent(
        sessionId: sessionId ?? '',
        type: 'error',
        data: 'Error streaming chat: $e',
      );
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

/// チャットレスポンスモデル
class AdkChatResponse {
  final String message;
  final String sessionId;
  final String eventType;
  final String? htmlOutput;
  final Map<String, dynamic>? metadata;

  AdkChatResponse({
    required this.message,
    required this.sessionId,
    required this.eventType,
    this.htmlOutput,
    this.metadata,
  });

  factory AdkChatResponse.fromJson(Map<String, dynamic> json) {
    return AdkChatResponse(
      message: json['message'],
      sessionId: json['session_id'],
      eventType: json['event_type'],
      htmlOutput: json['html_output'],
      metadata: json['metadata'],
    );
  }
}

/// 学級通信生成レスポンスモデル
class NewsletterGenerationResponse {
  final String sessionId;
  final String status;
  final String? htmlContent;
  final Map<String, dynamic>? jsonStructure;
  final List<ChatMessage> messages;

  NewsletterGenerationResponse({
    required this.sessionId,
    required this.status,
    this.htmlContent,
    this.jsonStructure,
    required this.messages,
  });

  factory NewsletterGenerationResponse.fromJson(Map<String, dynamic> json) {
    return NewsletterGenerationResponse(
      sessionId: json['session_id'],
      status: json['status'],
      htmlContent: json['html_content'],
      jsonStructure: json['json_structure'],
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
    );
  }
}

/// セッション情報モデル
class SessionInfo {
  final String sessionId;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final String status;
  final Map<String, dynamic>? agentState;

  SessionInfo({
    required this.sessionId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    required this.status,
    this.agentState,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      sessionId: json['session_id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
      status: json['status'],
      agentState: json['agent_state'],
    );
  }
}

/// チャットメッセージモデル
class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// エージェントイベントモデル（WebSocket用）
class AdkAgentEvent {
  final String eventId;
  final String eventType;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  AdkAgentEvent({
    required this.eventId,
    required this.eventType,
    required this.data,
    required this.timestamp,
  });

  factory AdkAgentEvent.fromJson(Map<String, dynamic> json) {
    return AdkAgentEvent(
      eventId: json['event_id'],
      eventType: json['event_type'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// ストリームイベントモデル（SSE用）
class AdkStreamEvent {
  final String sessionId;
  final String type;
  final String data;

  AdkStreamEvent({
    required this.sessionId,
    required this.type,
    required this.data,
  });

  factory AdkStreamEvent.fromJson(Map<String, dynamic> json) {
    return AdkStreamEvent(
      sessionId: json['session_id'],
      type: json['type'],
      data: json['data'],
    );
  }
}