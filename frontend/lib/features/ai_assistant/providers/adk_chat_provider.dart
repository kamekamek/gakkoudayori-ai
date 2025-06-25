import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../services/adk_agent_service.dart';
import '../../../services/audio_service.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/providers/error_provider.dart';

/// ADKチャットの状態管理プロバイダー
class AdkChatProvider extends ChangeNotifier {
  final AdkAgentService _adkService;
  final AudioService _audioService = AudioService();
  final ErrorProvider _errorProvider;
  final String userId;

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
    required ErrorProvider errorProvider,
    required this.userId,
  }) : _adkService = adkService,
       _errorProvider = errorProvider {
    _initializeAudioService();
  }

  void _initializeAudioService() {
    debugPrint('[AdkChatProvider] Initializing audio service...');
    
    try {
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
    } catch (error, stackTrace) {
      _errorProvider.reportError(
        AudioException.notSupported(),
        stackTrace: stackTrace,
        context: 'Audio service initialization',
      );
    }
  }

  /// メッセージを送信（ストリーミング対応）
  Future<void> sendMessage(String message) async {
    await _errorProvider.retryOperation(
      () => _sendMessageWithRetry(message),
      context: 'Sending chat message',
    );
  }

  /// リトライ機能付きメッセージ送信の実装
  Future<void> _sendMessageWithRetry(String message) async {
    debugPrint('[AdkChatProvider] sendMessage called with message: "$message"');
    
    if (_isProcessing) {
      debugPrint('[AdkChatProvider] Already processing, aborting.');
      throw ApiException.badRequest('Already processing another message');
    }

    if (message.trim().isEmpty) {
      throw ValidationException.required('message');
    }

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
      debugPrint('[AdkChatProvider] Starting stream process...');
      // アシスタントメッセージを準備
      final assistantMessage = MutableChatMessage(
        role: 'assistant',
        content: '',
        timestamp: DateTime.now(),
      );
      _messages.add(assistantMessage);

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
            _handleMessageEvent(event, assistantMessage);
            break;
          case 'complete':
            _handleCompleteEvent(event);
            break;
          case 'error':
            _handleErrorEvent(event);
            break;
        }
      }
      debugPrint('[AdkChatProvider] Stream finished.');
    } catch (e, stackTrace) {
      // エラーを適切な例外に変換
      final exception = _convertToAppException(e);
      _error = exception.userMessage;
      
      // エラープロバイダーに報告
      _errorProvider.reportError(
        exception,
        stackTrace: stackTrace,
        context: 'Chat message streaming',
      );
      
      debugPrint('[AdkChatProvider] Error in sendMessage: $e');
      rethrow;
    } finally {
      _isProcessing = false;
      debugPrint('[AdkChatProvider] Set isProcessing to false.');
      notifyListeners();
    }
  }

  /// メッセージイベントを処理
  void _handleMessageEvent(AdkStreamEvent event, MutableChatMessage assistantMessage) {
    try {
      final messageData = jsonDecode(event.data);
      final content = messageData['content'] ?? '';
      final eventType = messageData['type'] ?? 'message';
      
      if (eventType == 'complete') {
        // HTML生成完了
        if (content.contains('<html>') || content.contains('<!DOCTYPE html>')) {
          _generatedHtml = content;
        }
        assistantMessage.content = content;
      } else {
        // 通常のメッセージ
        assistantMessage.content = content;
      }
      notifyListeners();
    } catch (e) {
      // JSON解析に失敗した場合は生のデータを使用
      assistantMessage.content = event.data;
      notifyListeners();
    }
  }

  /// 完了イベントを処理
  void _handleCompleteEvent(AdkStreamEvent event) {
    try {
      // HTML生成完了
      _generatedHtml = event.data;
      notifyListeners();
    } catch (e) {
      debugPrint('[AdkChatProvider] Error handling complete event: $e');
    }
  }

  /// エラーイベントを処理
  void _handleErrorEvent(AdkStreamEvent event) {
    final errorMessage = event.data;
    _error = errorMessage;
    
    // サーバーからのエラーを適切な例外に変換
    final exception = ApiException.serverError(errorMessage);
    _errorProvider.reportError(
      exception,
      context: 'Server error event',
    );
    
    notifyListeners();
  }

  /// エラーをAppExceptionに変換
  AppException _convertToAppException(dynamic error) {
    if (error is AppException) {
      return error;
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('timeout') || errorString.contains('connection')) {
      return NetworkException.timeout();
    }
    
    if (errorString.contains('permission')) {
      return PermissionException.microphoneDenied();
    }
    
    if (errorString.contains('session')) {
      return SessionException.notFound();
    }
    
    // デフォルトはAPIエラー
    return ApiException.serverError(error.toString());
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
    
    try {
      final result = await _audioService.startRecording();
      debugPrint('[AdkChatProvider] startVoiceRecording result: $result');
      
      if (!result) {
        throw AudioException.recordingFailed('Failed to start recording');
      }
      
      return result;
    } catch (error, stackTrace) {
      final exception = error is AudioException 
          ? error 
          : AudioException.recordingFailed(error);
      
      _errorProvider.reportError(
        exception,
        stackTrace: stackTrace,
        context: 'Starting voice recording',
      );
      
      return false;
    }
  }

  /// 音声録音停止
  Future<bool> stopVoiceRecording() async {
    debugPrint('[AdkChatProvider] stopVoiceRecording called');
    
    try {
      final result = await _audioService.stopRecording();
      debugPrint('[AdkChatProvider] stopVoiceRecording result: $result');
      
      if (!result) {
        throw AudioException.recordingFailed('Failed to stop recording');
      }
      
      return result;
    } catch (error, stackTrace) {
      final exception = error is AudioException 
          ? error 
          : AudioException.recordingFailed(error);
      
      _errorProvider.reportError(
        exception,
        stackTrace: stackTrace,
        context: 'Stopping voice recording',
      );
      
      return false;
    }
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
