import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

/// HTML Artifact WebSocket サービス
/// LayoutAgentからのHTML成果物をリアルタイムで受信
class ArtifactWebSocketService {
  WebSocketChannel? _channel;
  final StreamController<HtmlArtifact> _artifactController =
      StreamController.broadcast();
  final StreamController<WebSocketConnectionState> _connectionController =
      StreamController.broadcast();

  String? _currentSessionId;
  bool _disposed = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 3);

  // Base URL設定（環境に応じて変更）
  String get _baseUrl {
    if (AppConfig.isDevelopment) {
      return AppConfig.currentWsBaseUrl;
    } else {
      // 本番環境ではhttp/httpsをws/wssに置換
      return AppConfig.currentApiBaseUrl.replaceFirst(RegExp(r'^http'), 'ws');
    }
  }

  // ストリーム
  Stream<HtmlArtifact> get artifactStream => _artifactController.stream;
  Stream<WebSocketConnectionState> get connectionStateStream =>
      _connectionController.stream;

  /// WebSocket接続を確立
  void connect(String sessionId) {
    if (_disposed) return;

    if (sessionId.isEmpty) {
      debugPrint(
          '[ArtifactWebSocket] ERROR: Empty session ID provided, aborting connection');
      return;
    }

    _currentSessionId = sessionId;
    debugPrint('[ArtifactWebSocket] Session ID set to: $_currentSessionId');
    _connectWebSocket();
  }

  void _connectWebSocket() {
    if (_disposed || _currentSessionId == null) return;

    try {
      debugPrint(
          '[ArtifactWebSocket] Connecting to: $_baseUrl/ws/artifacts/$_currentSessionId');

      _channel = WebSocketChannel.connect(
          Uri.parse('$_baseUrl/ws/artifacts/$_currentSessionId'));

      _connectionController.add(WebSocketConnectionState.connecting);

      // WebSocketメッセージを監視
      _channel!.stream.listen(
        (data) {
          _handleWebSocketMessage(data);
        },
        onError: (error) {
          debugPrint('[ArtifactWebSocket] Error: $error');
          _connectionController.add(WebSocketConnectionState.error);
          _handleReconnect();
        },
        onDone: () {
          debugPrint('[ArtifactWebSocket] Connection closed');
          _connectionController.add(WebSocketConnectionState.disconnected);
          _handleReconnect();
        },
      );

      // 接続成功
      _connectionController.add(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;
      debugPrint('[ArtifactWebSocket] Connected successfully');

      // 定期的なping送信でコネクション維持
      _startPingTimer();
    } catch (e) {
      debugPrint('[ArtifactWebSocket] Connection failed: $e');
      _connectionController.add(WebSocketConnectionState.error);
      _handleReconnect();
    }
  }

  void _handleWebSocketMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = jsonDecode(data);

      if (message['type'] == 'html_artifact') {
        final artifactData = message['data'] as Map<String, dynamic>;
        final artifact = HtmlArtifact.fromJson(artifactData);

        debugPrint(
            '[ArtifactWebSocket] Received HTML artifact: ${artifact.content.length} chars');
        _artifactController.add(artifact);
      }
    } catch (e) {
      debugPrint('[ArtifactWebSocket] Failed to parse message: $e');
    }
  }

  void _startPingTimer() {
    Timer.periodic(Duration(seconds: 30), (timer) {
      if (_disposed || _channel == null) {
        timer.cancel();
        return;
      }

      try {
        _channel!.sink.add('ping');
      } catch (e) {
        debugPrint('[ArtifactWebSocket] Ping failed: $e');
        timer.cancel();
      }
    });
  }

  void _handleReconnect() {
    if (_disposed || _reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('[ArtifactWebSocket] Max reconnect attempts reached');
      return;
    }

    _reconnectAttempts++;
    debugPrint('[ArtifactWebSocket] Attempting reconnect #$_reconnectAttempts');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      _connectWebSocket();
    });
  }

  /// WebSocket接続を切断
  void disconnect() {
    _reconnectTimer?.cancel();

    try {
      _channel?.sink.close();
    } catch (e) {
      debugPrint('[ArtifactWebSocket] Error closing channel: $e');
    }

    _channel = null;
    _currentSessionId = null;
    _reconnectAttempts = 0;

    if (!_disposed) {
      _connectionController.add(WebSocketConnectionState.disconnected);
    }

    debugPrint('[ArtifactWebSocket] Disconnected');
  }

  /// リソースの解放
  void dispose() {
    _disposed = true;
    disconnect();
    _artifactController.close();
    _connectionController.close();
    debugPrint('[ArtifactWebSocket] Disposed');
  }

  /// 現在の接続状態
  bool get isConnected => _channel != null && _currentSessionId != null;
}

/// HTML Artifact データクラス
class HtmlArtifact {
  final String sessionId;
  final String content;
  final String artifactType;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  HtmlArtifact({
    required this.sessionId,
    required this.content,
    required this.artifactType,
    required this.createdAt,
    this.metadata = const {},
  });

  factory HtmlArtifact.fromJson(Map<String, dynamic> json) {
    return HtmlArtifact(
      sessionId: json['session_id'] ?? '',
      content: json['content'] ?? '',
      artifactType: json['artifact_type'] ?? 'newsletter',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'content': content,
      'artifact_type': artifactType,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// WebSocket接続状態
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}
