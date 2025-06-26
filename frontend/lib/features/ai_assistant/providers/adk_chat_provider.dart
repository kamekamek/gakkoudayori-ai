import 'package:flutter/foundation.dart';
import '../../../services/adk_agent_service.dart';
import '../../../services/adk_agent_service_mock.dart';
import '../../../services/audio_service.dart';
import '../../../services/audio_service_mock.dart';

/// ADKチャットの状態管理プロバイダー
class AdkChatProvider extends ChangeNotifier {
  final AdkAgentService _adkService;
  final dynamic _audioService; // AudioService or AudioServiceMock
  final String userId;
  final bool _isDemo;

  // 状態
  final List<MutableChatMessage> _messages = [];
  String? _sessionId;
  bool _isProcessing = false;
  String? _error;
  String? _generatedHtml;

  // 音声関連状態
  bool _isVoiceRecording = false;
  double _audioLevel = 0.0;
  String? _transcriptionResult;

  // ゲッター
  List<MutableChatMessage> get messages => _messages;
  String? get sessionId => _sessionId;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String? get generatedHtml => _generatedHtml;
  bool get isVoiceRecording => _isVoiceRecording;
  double get audioLevel => _audioLevel;
  String? get transcriptionResult => _transcriptionResult;

  AdkChatProvider({
    required AdkAgentService adkService,
    required this.userId,
    bool isDemo = false,
  })  : _adkService = adkService,
        _isDemo = isDemo,
        _audioService = isDemo ? AudioServiceMock() : AudioService() {
    _initializeAudioService();
  }

  /// ファクトリコンストラクタ：デモモード用
  factory AdkChatProvider.demo({
    required String userId,
  }) {
    return AdkChatProvider(
      adkService: AdkAgentServiceMock(),
      userId: userId,
      isDemo: true,
    );
  }

  void _initializeAudioService() {
    debugPrint(
        '[AdkChatProvider] Initializing audio service... (Demo mode: $_isDemo)');
    _audioService.initializeJavaScriptBridge();

    _audioService.setOnRecordingStateChanged((isRecording) {
      debugPrint('[AdkChatProvider] Recording state changed: $isRecording');
      _isVoiceRecording = isRecording;
      notifyListeners();
    });

    _audioService.setOnTranscriptionCompleted((transcript) {
      debugPrint('[AdkChatProvider] Transcription completed: $transcript');
      _transcriptionResult = transcript;
      notifyListeners();
    });

    _audioService.setOnAudioLevelChanged((level) {
      _audioLevel = level;
      notifyListeners();
    });

    debugPrint('[AdkChatProvider] Audio service initialization complete');
  }

  /// ユーザーメッセージを即座にUIに追加
  void addUserMessage(String message) {
    _messages.add(MutableChatMessage(
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    ));
    _transcriptionResult = null; // 入力欄をクリアするために文字起こし結果をリセット
    notifyListeners();
  }

  /// メッセージを送信（ストリーミング対応）
  Future<void> sendMessage(String message) async {
    debugPrint('[AdkChatProvider] sendMessage called with message: "$message"');
    if (_isProcessing) {
      debugPrint('[AdkChatProvider] Already processing, aborting.');
      return;
    }

    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[AdkChatProvider] Starting stream process...');
      // アシスタントメッセージを準備（最初のテキストが来るまで追加しない）
      MutableChatMessage? assistantMessage;

      // ストリーミング開始
      debugPrint('[AdkChatProvider] Calling _adkService.streamChatSSE...');
      final stream = _adkService.streamChatSSE(
        message: message,
        userId: userId,
        sessionId: _sessionId,
      );

      await for (final event in stream) {
        _sessionId = event.sessionId;
        debugPrint(
            '[AdkChatProvider] Received stream event: type=${event.type}, data=${event.data}');

        switch (event.type) {
          case 'message':
            // 最初のテキストが来た時にアシスタントメッセージを作成
            if (assistantMessage == null) {
              assistantMessage = MutableChatMessage(
                role: 'assistant',
                content: event.data,
                timestamp: DateTime.now(),
              );
              _messages.add(assistantMessage);
            } else {
              // メッセージを追加していく
              assistantMessage.content += event.data;
            }
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
      debugPrint('[AdkChatProvider] Stream finished.');
    } catch (e) {
      _error = e.toString();
      debugPrint('[AdkChatProvider] Error in sendMessage: $e');
    } finally {
      _isProcessing = false;
      debugPrint('[AdkChatProvider] Set isProcessing to false.');
      notifyListeners();
    }
  }

  /// セッションをクリア
  void clearSession() {
    _messages.clear();
    _sessionId = null;
    _generatedHtml = null;
    _error = null;
    _transcriptionResult = null;
    _audioLevel = 0.0;
    notifyListeners();
  }

  /// エラーをクリア
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 音声録音開始
  Future<bool> startVoiceRecording() async {
    debugPrint('[AdkChatProvider] startVoiceRecording called');
    final result = await _audioService.startRecording();
    debugPrint('[AdkChatProvider] startVoiceRecording result: $result');
    return result;
  }

  /// 音声録音停止
  Future<bool> stopVoiceRecording() async {
    debugPrint('[AdkChatProvider] stopVoiceRecording called');
    final result = await _audioService.stopRecording();
    debugPrint('[AdkChatProvider] stopVoiceRecording result: $result');
    return result;
  }

  /// 学級通信生成を開始すべきかチェック
  bool _shouldStartNewsletterGeneration(String message) {
    final lowerMessage = message.toLowerCase();
    return lowerMessage.contains('学級通信') ||
        lowerMessage.contains('がっきゅうつうしん') ||
        lowerMessage.contains('おたより') ||
        lowerMessage.contains('newsletter');
  }

  /// 便利メソッド：デモモードかどうかをチェック
  bool get isDemo => _isDemo;

  /// 便利メソッド：デモ用のサンプルメッセージを追加
  void addDemoMessage(String role, String content) {
    if (_isDemo) {
      _messages.add(MutableChatMessage(
        role: role,
        content: content,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    }
  }

  /// 便利メソッド：デモ用のHTMLコンテンツを直接設定
  void setDemoHtmlContent(String htmlContent) {
    if (_isDemo) {
      _generatedHtml = htmlContent;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_audioService != null) {
      _audioService.dispose();
    }
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
