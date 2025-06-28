import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../services/adk_agent_service.dart';
import '../../../services/audio_service.dart';
import '../../../core/providers/error_provider.dart';
import '../../../core/models/chat_message.dart';

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

  // プロバイダーの生存状態を追跡
  bool _disposed = false;

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
  })  : _adkService = adkService,
        _errorProvider = errorProvider {
    _initializeAudioService();
  }

  /// 安全なnotifyListeners呼び出し
  void _safeNotifyListeners() {
    if (!_disposed && hasListeners) {
      try {
        notifyListeners();
      } catch (e) {
        debugPrint('[AdkChatProvider] Error in notifyListeners: $e');
      }
    }
  }

  void _initializeAudioService() {
    debugPrint('[AdkChatProvider] Initializing audio service...');

    try {
      _audioService.initializeJavaScriptBridge();

      _audioService.setOnRecordingStateChanged((isRecording) {
        if (_disposed) return;
        debugPrint('[AdkChatProvider] Recording state changed: $isRecording');
        _isVoiceRecording = isRecording;
        _safeNotifyListeners();
      });

      _audioService.setOnTranscriptionCompleted((transcript) {
        if (_disposed) return;
        debugPrint('[AdkChatProvider] Transcription completed: $transcript');
        _transcriptionResult = transcript;
        _safeNotifyListeners();
      });

      _audioService.setOnAudioLevelChanged((level) {
        if (_disposed) return;
        _audioLevel = level;
        _safeNotifyListeners();
      });

      debugPrint('[AdkChatProvider] Audio service initialization complete');
    } catch (error) {
      _errorProvider.setError('Audio service initialization failed: $error');
      debugPrint('Audio service initialization error: $error');
    }
  }

  /// メッセージを送信（ストリーミング対応）
  Future<void> sendMessage(String message) async {
    try {
      await _sendMessageWithRetry(message);
    } catch (error) {
      _errorProvider.setError('Failed to send message: $error');
      rethrow;
    }
  }

  /// リトライ機能付きメッセージ送信の実装
  Future<void> _sendMessageWithRetry(String message) async {
    debugPrint('[AdkChatProvider] sendMessage called with message: "$message"');

    if (_isProcessing) {
      debugPrint('[AdkChatProvider] Already processing, aborting.');
      throw Exception('Already processing another message');
    }

    if (message.trim().isEmpty) {
      throw Exception('Message is required');
    }

    // ユーザーメッセージを追加
    _messages.add(MutableChatMessage(
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    ));

    _isProcessing = true;
    _error = null;
    _safeNotifyListeners();

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
        if (_disposed) break; // 破棄された場合は処理を停止

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
          case 'html_generated':
            _handleHtmlGeneratedEvent(event);
            break;
        }
      }
      debugPrint('[AdkChatProvider] Stream finished.');
    } catch (e) {
      _error = e.toString();
      _errorProvider.setError('Chat error: ${e.toString()}');
      debugPrint('[AdkChatProvider] Error in sendMessage: $e');
    } finally {
      _isProcessing = false;
      debugPrint('[AdkChatProvider] Set isProcessing to false.');
      _safeNotifyListeners();
    }
  }

  /// メッセージイベントを処理（簡素化版）
  void _handleMessageEvent(
      AdkStreamEvent event, MutableChatMessage assistantMessage) {
    if (_disposed) return;

    try {
      final messageData = jsonDecode(event.data);
      final contentData = messageData['content'];

      // contentからテキストを抽出
      String extractedText = '';

      if (contentData is Map<String, dynamic>) {
        final parts = contentData['parts'];
        if (parts is List) {
          for (final part in parts) {
            if (part is Map<String, dynamic> && part['text'] != null) {
              extractedText += part['text'] as String;
            }
          }
        }
      } else if (contentData is String) {
        extractedText = contentData;
      }

      // HTML生成完了のチェック
      if (extractedText.contains('<html>') ||
          extractedText.contains('<!DOCTYPE html>')) {
        _generatedHtml = extractedText;
        assistantMessage.content = '🎉 学級通信が完成しました！編集タブでご確認ください。';
      } else {
        // 通常のメッセージとして表示
        if (extractedText.isNotEmpty) {
          assistantMessage.content += extractedText;
        }
      }
      
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('[AdkChatProvider] Error parsing message event: $e');
      // エラーの場合は簡潔なメッセージを表示
      assistantMessage.content = 'メッセージの処理中にエラーが発生しました。';
      _safeNotifyListeners();
    }
  }

  /// 完了イベントを処理
  void _handleCompleteEvent(AdkStreamEvent event) {
    if (_disposed) return;

    try {
      // HTML生成完了
      _generatedHtml = event.data;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('[AdkChatProvider] Error handling complete event: $e');
    }
  }

  /// エラーイベントを処理
  void _handleErrorEvent(AdkStreamEvent event) {
    if (_disposed) return;

    final errorMessage = event.data;
    _error = errorMessage;

    // エラーを記録
    _errorProvider.setError('Server error: $errorMessage');

    _safeNotifyListeners();
  }

  /// HTML生成完了イベントを処理
  void _handleHtmlGeneratedEvent(AdkStreamEvent event) {
    if (_disposed) return;

    try {
      final messageData = jsonDecode(event.data);
      final htmlContent = messageData['html_content'];

      if (htmlContent != null && htmlContent is String) {
        _generatedHtml = htmlContent;
        debugPrint(
            '[AdkChatProvider] HTML generated successfully: ${htmlContent.length} characters');
      }

      _safeNotifyListeners();
    } catch (e) {
      debugPrint('[AdkChatProvider] Error handling HTML generated event: $e');
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
    _safeNotifyListeners();
  }

  /// エラーをクリア
  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }

  /// 音声認識結果をクリア
  void clearTranscriptionResult() {
    _transcriptionResult = null;
    _safeNotifyListeners();
  }

  /// 音声録音開始
  Future<bool> startVoiceRecording() async {
    debugPrint('[AdkChatProvider] startVoiceRecording called');

    try {
      final result = await _audioService.startRecording();
      debugPrint('[AdkChatProvider] startVoiceRecording result: $result');

      if (!result) {
        throw Exception('Failed to start recording');
      }

      return result;
    } catch (error) {
      _errorProvider.setError('Failed to start voice recording: $error');
      debugPrint('Voice recording start error: $error');
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
        throw Exception('Failed to stop recording');
      }

      return result;
    } catch (error) {
      _errorProvider.setError('Failed to stop voice recording: $error');
      debugPrint('Voice recording stop error: $error');
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
    _disposed = true;
    _adkService.dispose();
    super.dispose();
  }
}
