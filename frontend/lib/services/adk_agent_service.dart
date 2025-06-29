import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import 'package:flutter/foundation.dart';
import '../core/exceptions/app_exceptions.dart';

/// ADKエージェントとの通信を管理するサービス
class AdkAgentService {
  String get _baseUrl => AppConfig.currentApiBaseUrl;
  final http.Client _httpClient = http.Client();

  /// Firebase認証トークンを安全に取得
  Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (kDebugMode) {
          debugPrint('⚠️ AdkAgentService: Firebaseユーザーがログインしていません');
        }
        return null;
      }
      
      final token = await user.getIdToken();
      if (token == null || token.trim().isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ AdkAgentService: 空の認証トークンが返されました');
        }
        return null;
      }
      
      return token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AdkAgentService: 認証トークン取得エラー: $e');
      }
      return null;
    }
  }

  /// 認証ヘッダーを安全に作成
  Future<Map<String, String>> _createHeaders({String? authToken}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    final token = authToken ?? await _getAuthToken();
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }
    
    return headers;
  }

  /// チャットメッセージをエージェントに送信
  Future<AdkChatResponse> sendChatMessage({
    required String message,
    required String userId,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 入力検証
      if (message.trim().isEmpty) {
        throw Exception('メッセージが空です。');
      }
      if (userId.trim().isEmpty) {
        throw Exception('ユーザーIDが空です。');
      }
      
      final url = Uri.parse('${AppConfig.currentApiBaseUrl}/api/v1/adk/chat/stream');
      final headers = await _createHeaders();
      
      if (kDebugMode) {
        debugPrint('🚀 [AdkAgentService] sendChatMessage開始');
        debugPrint('🔗 AppConfig.currentApiBaseUrl: ${AppConfig.currentApiBaseUrl}');
        debugPrint('🔗 構築されたURL: $url');
        debugPrint('📨 送信データ: {"message":"$message","session_id":"$sessionId"}');
      }
      
      final response = await _httpClient
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'session': sessionId?.trim(),
              'message': message.trim(),
              'user_id': userId.trim(),
              'metadata': metadata ?? {},
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.isEmpty) {
          throw Exception('サーバーから空のレスポンスが返されました。');
        }
        
        final dynamic data = jsonDecode(responseBody);
        if (data == null) {
          throw Exception('サーバーからnullレスポンスが返されました。');
        }
        
        return AdkChatResponse.fromJson(data);
      } else {
        throw _createApiException(response);
      }
    } on TimeoutException {
      throw NetworkException.timeout();
    } catch (e) {
      throw _convertToAppException(e, 'sending chat message');
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
        throw Exception(
            'Failed to start newsletter generation: ${response.body}');
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
      // 入力検証
      if (message.trim().isEmpty) {
        yield AdkStreamEvent(
          sessionId: sessionId ?? '',
          type: 'error',
          data: 'メッセージが空です。',
        );
        return;
      }
      if (userId.trim().isEmpty) {
        yield AdkStreamEvent(
          sessionId: sessionId ?? '',
          type: 'error',
          data: 'ユーザーIDが空です。',
        );
        return;
      }

      final token = await _getAuthToken();
      if (token == null) {
        yield AdkStreamEvent(
          sessionId: sessionId ?? '',
          type: 'error',
          data: '認証が必要です。ログインしてください。',
        );
        return;
      }

      final url = Uri.parse('$_baseUrl/api/v1/adk/chat/stream');
      final cleanSessionId = sessionId?.trim().isNotEmpty == true 
          ? sessionId!.trim() 
          : '${userId.trim()}:default';
      final body = {
        'message': message.trim(),
        'session_id': cleanSessionId,
      };

      debugPrint('🚀 [AdkAgentService] streamChatSSE開始');
      debugPrint('🔗 _baseUrl: $_baseUrl');
      debugPrint('🔗 構築されたURL: $url');
      debugPrint(
          '[AdkAgentService] Sending POST request to $url with body: ${jsonEncode(body)}');

      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token'
        ..body = jsonEncode(body);

      final response = await _httpClient.send(request);

      debugPrint(
          '[AdkAgentService] Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        yield* response.stream
            .transform(utf8.decoder)
            .transform(LineSplitter())
            .map((line) {
              if (line.startsWith('data: ')) {
                final data = line.substring(6);
                if (data.trim().isNotEmpty) {
                  try {
                    final decodedData = jsonDecode(data);
                    // バックエンドから返される形式に対応
                    if (decodedData is Map<String, dynamic>) {
                      final eventSessionId = decodedData['session_id'];
                      final eventType = decodedData['type'];
                      final eventData = decodedData['data'];
                      
                      return AdkStreamEvent(
                        sessionId: (eventSessionId is String && eventSessionId.isNotEmpty) 
                            ? eventSessionId 
                            : cleanSessionId,
                        type: (eventType is String && eventType.isNotEmpty) 
                            ? eventType 
                            : 'message',
                        data: (eventData is String && eventData.isNotEmpty) 
                            ? eventData 
                            : data,
                      );
                    } else {
                      // フォールバック処理
                      try {
                        return AdkStreamEvent.fromJson(decodedData);
                      } catch (e) {
                        return AdkStreamEvent(
                          sessionId: cleanSessionId,
                          type: 'error',
                          data: 'Invalid event format: $e',
                        );
                      }
                    }
                  } catch (e) {
                    return AdkStreamEvent(
                      sessionId: cleanSessionId,
                      type: 'error',
                      data: 'Error parsing SSE data: $e',
                    );
                  }
                }
              }
              return null;
            })
            .where((event) => event != null)
            .cast<AdkStreamEvent>();
      } else {
        final decodedBody = await response.stream.bytesToString();
        debugPrint('[AdkAgentService] Error response body: $decodedBody');
        yield AdkStreamEvent(
          sessionId: cleanSessionId,
          type: 'error',
          data: 'Failed to stream chat: ${response.statusCode}, Body: $decodedBody',
        );
      }
    } catch (e) {
      debugPrint('[AdkAgentService] Exception caught: $e');
      yield AdkStreamEvent(
        sessionId: sessionId?.trim() ?? '',
        type: 'error',
        data: 'Error streaming chat: $e',
      );
    }
  }

  /// 学級通信を生成する
  Future<String> generateNewsletter({
    required String userId,
    required String sessionId,
  }) async {
    try {
      // 入力検証
      if (userId.trim().isEmpty) {
        throw Exception('ユーザーIDが空です。');
      }
      if (sessionId.trim().isEmpty) {
        throw Exception('セッションIDが空です。');
      }

      final url = Uri.parse('$_baseUrl/adk/newsletter/generate');
      final headers = await _createHeaders();
      final body = jsonEncode({
        'user_id': userId.trim(),
        'session_id': sessionId.trim(),
      });
      debugPrint('[AdkAgentService] Generating newsletter with body: $body');

      final response = await _httpClient.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.isEmpty) {
          throw Exception('サーバーから空のレスポンスが返されました。');
        }
        
        final dynamic data = jsonDecode(responseBody);
        if (data == null) {
          throw Exception('サーバーからnullレスポンスが返されました。');
        }
        
        final htmlContent = data['html_content'];
        if (htmlContent is! String || htmlContent.trim().isEmpty) {
          throw Exception('HTMLコンテンツが空または無効です。');
        }
        
        debugPrint('[AdkAgentService] Newsletter generated successfully.');
        return htmlContent;
      } else {
        debugPrint(
            '[AdkAgentService] Failed to generate newsletter. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to generate newsletter: ${response.body}');
      }
    } catch (e) {
      debugPrint('[AdkAgentService] Error generating newsletter: $e');
      rethrow;
    }
  }

  /// HTTPレスポンスからAPIExceptionを作成
  ApiException _createApiException(http.Response response) {
    Map<String, dynamic>? responseData;
    try {
      responseData = jsonDecode(response.body);
    } catch (_) {
      // JSON解析に失敗した場合は無視
    }

    switch (response.statusCode) {
      case 400:
        return ApiException.badRequest(
          responseData?['message'] ?? 'Bad request',
          responseData,
        );
      case 401:
        return ApiException.unauthorized();
      case 403:
        return ApiException.forbidden();
      case 404:
        return ApiException.notFound();
      case 500:
      case 502:
      case 503:
      case 504:
        return ApiException.serverError(
          responseData?['message'] ?? 'Server error',
        );
      default:
        return ApiException(
          message: responseData?['message'] ?? 'API error',
          statusCode: response.statusCode,
          responseData: responseData,
        );
    }
  }

  /// 一般的なエラーをAppExceptionに変換
  AppException _convertToAppException(dynamic error, String context) {
    if (error is AppException) {
      return error;
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return NetworkException.timeout();
    }

    if (errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('socket')) {
      return NetworkException.connectionLost();
    }

    if (errorString.contains('format') || errorString.contains('parse')) {
      return ContentException.parsingFailed(error);
    }

    return ApiException(
      message: 'Error $context: ${error.toString()}',
      originalError: error,
    );
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
