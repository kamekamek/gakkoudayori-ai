import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../services/adk_agent_service.dart';
import '../../../services/audio_service.dart';
import '../../../services/artifact_websocket_service.dart';
import '../../../core/providers/error_provider.dart';
import '../../../core/models/chat_message.dart';
import '../../editor/providers/preview_provider.dart';

/// ADKチャットの状態管理プロバイダー
class AdkChatProvider extends ChangeNotifier {
  final AdkAgentService _adkService;
  final AudioService _audioService = AudioService();
  final ArtifactWebSocketService _artifactWebSocketService = ArtifactWebSocketService();
  final ErrorProvider _errorProvider;
  final String userId;
  PreviewProvider? _previewProvider;

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

  // 学級通信生成ボタン関連状態
  bool _showGenerateButton = false;
  bool _readyToGenerate = false;

  // ゲッター
  List<MutableChatMessage> get messages => _messages;
  String? get sessionId => _sessionId;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String? get generatedHtml => _generatedHtml;
  bool get isVoiceRecording => _isVoiceRecording;
  double get audioLevel => _audioLevel;
  String? get transcriptionResult => _transcriptionResult;
  bool get showGenerateButton => _showGenerateButton;
  bool get readyToGenerate => _readyToGenerate;

  AdkChatProvider({
    required AdkAgentService adkService,
    required ErrorProvider errorProvider,
    required this.userId,
  })  : _adkService = adkService,
        _errorProvider = errorProvider {
    _initializeAudioService();
    _initializeWebSocketService();
  }

  /// PreviewProviderを設定
  void setPreviewProvider(PreviewProvider previewProvider) {
    _previewProvider = previewProvider;
    debugPrint('[AdkChatProvider] PreviewProvider設定完了: ${previewProvider.runtimeType}');
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

  void _initializeWebSocketService() {
    debugPrint('[AdkChatProvider] Initializing WebSocket service...');

    try {
      // HTML Artifactを受信したときの処理
      _artifactWebSocketService.artifactStream.listen((artifact) {
        if (_disposed) return;
        
        debugPrint('[AdkChatProvider] Received HTML artifact: ${artifact.content.length} chars');
        
        // 受信したHTMLをPreviewProviderに渡す
        _generatedHtml = artifact.content;
        _notifyPreviewProvider(artifact.content);
        
        // チャットに成功メッセージを追加
        final successMessage = MutableChatMessage(
          role: 'assistant',
          content: '🎉 学級通信が完成しました！プレビューをご確認ください。',
          timestamp: DateTime.now(),
        );
        _messages.add(successMessage);
        
        _safeNotifyListeners();
      });

      // WebSocket接続状態の監視
      _artifactWebSocketService.connectionStateStream.listen((state) {
        if (_disposed) return;
        
        debugPrint('[AdkChatProvider] WebSocket state: $state');
        
        switch (state) {
          case WebSocketConnectionState.connected:
            debugPrint('[AdkChatProvider] WebSocket connected successfully');
            break;
          case WebSocketConnectionState.error:
            debugPrint('[AdkChatProvider] WebSocket connection error');
            break;
          case WebSocketConnectionState.disconnected:
            debugPrint('[AdkChatProvider] WebSocket disconnected');
            break;
          case WebSocketConnectionState.connecting:
            debugPrint('[AdkChatProvider] WebSocket connecting...');
            break;
        }
      });

      debugPrint('[AdkChatProvider] WebSocket service initialization complete');
    } catch (error) {
      _errorProvider.setError('WebSocket service initialization failed: $error');
      debugPrint('WebSocket service initialization error: $error');
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
    
    // セッションIDが未設定の場合は初期化
    if (_sessionId == null) {
      _sessionId = '${userId}:default';
      debugPrint('[AdkChatProvider] Initializing session ID: $_sessionId');
    }
    
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

      // WebSocket接続を事前確立
      _connectWebSocketIfNeeded();
      
      // ストリーミング開始
      debugPrint('[AdkChatProvider] Calling _adkService.streamChatSSE...');
      final stream = _adkService.streamChatSSE(
        message: message,
        userId: userId,
        sessionId: _sessionId,
      );

      await for (final event in stream) {
        if (_disposed) break; // 破棄された場合は処理を停止

        // セッションIDが更新された場合、WebSocket接続を確立
        if (event.sessionId != null && _sessionId != event.sessionId) {
          _sessionId = event.sessionId;
          _connectWebSocketIfNeeded();
        } else if (_sessionId == null) {
          // セッションIDが設定されていない場合は強制設定
          _sessionId = '${userId}:default';
          debugPrint('[AdkChatProvider] Force setting session ID: $_sessionId');
          _connectWebSocketIfNeeded();
        }
        
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
      
      // 生成ボタンの表示判定
      _updateGenerateButtonVisibility();
      
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

      // 新しい専用HTML完了タグをチェック（優先）
      if (extractedText.contains('<html_ready>')) {
        // 新しいHTML完了通知からHTMLを抽出
        final htmlStartTag = '<html_ready>';
        final htmlEndTag = '</html_ready>';
        final startIndex = extractedText.indexOf(htmlStartTag);
        final endIndex = extractedText.indexOf(htmlEndTag);
        
        if (startIndex != -1 && endIndex != -1) {
          final htmlContent = extractedText.substring(
            startIndex + htmlStartTag.length, 
            endIndex
          );
          _generatedHtml = htmlContent;
          assistantMessage.content = '🎉 学級通信が完成しました！プレビューをご確認ください。';
          
          // PreviewProviderにHTMLを渡す
          _notifyPreviewProvider(htmlContent);
          
          debugPrint('[AdkChatProvider] HTML ready extracted: ${htmlContent.length} characters');
          return; // HTMLが見つかったので処理終了
        }
      }
      
      // フォールバック: 従来のHTML検出方法
      if (extractedText.contains('<html_generated>')) {
        // 旧HTML完了通知からHTMLを抽出
        final htmlStartTag = '<html_generated>';
        final htmlEndTag = '</html_generated>';
        final startIndex = extractedText.indexOf(htmlStartTag);
        final endIndex = extractedText.indexOf(htmlEndTag);
        
        if (startIndex != -1 && endIndex != -1) {
          final htmlContent = extractedText.substring(
            startIndex + htmlStartTag.length, 
            endIndex
          );
          _generatedHtml = htmlContent;
          assistantMessage.content = '🎉 学級通信が完成しました！プレビューをご確認ください。';
          _notifyPreviewProvider(htmlContent);
          debugPrint('[AdkChatProvider] HTML extracted (legacy): ${htmlContent.length} characters');
          return; // HTMLが見つかったので処理終了
        }
      }
      
      // 最終フォールバック: 直接HTML検出
      if (extractedText.contains('<html>') || extractedText.contains('<!DOCTYPE html>')) {
        _generatedHtml = extractedText;
        assistantMessage.content = '🎉 学級通信が完成しました！プレビューをご確認ください。';
        _notifyPreviewProvider(extractedText);
        debugPrint('[AdkChatProvider] Direct HTML detected: ${extractedText.length} characters');
        return; // HTMLが見つかったので処理終了
      }
      
      // 通常のメッセージとして表示（HTMLではない場合）
      if (extractedText.isNotEmpty) {
        assistantMessage.content += extractedText;
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
    _showGenerateButton = false;
    _readyToGenerate = false;
    _safeNotifyListeners();
  }

  /// エラーをクリア
  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }

  /// 生成ボタンの表示判定を更新
  void _updateGenerateButtonVisibility() {
    // 基本情報が含まれているかチェック
    bool hasBasicInfo = _hasBasicNewsletterInfo();
    
    // 既にHTML生成済みでないかチェック
    bool notGenerated = _generatedHtml == null || _generatedHtml!.isEmpty;
    
    // 生成ボタンを表示する条件
    _showGenerateButton = hasBasicInfo && notGenerated && !_isProcessing;
    _readyToGenerate = _showGenerateButton;
    
    debugPrint('[AdkChatProvider] Generate button visibility: show=$_showGenerateButton, ready=$_readyToGenerate');
  }

  /// 基本的な学級通信情報が含まれているかチェック
  bool _hasBasicNewsletterInfo() {
    // メッセージ履歴から必要な情報が含まれているかを簡易判定
    String conversationText = _messages.map((m) => m.content).join(' ');
    
    // 学校名、学年、先生名、内容のいずれかが含まれていることを確認
    bool hasSchoolInfo = conversationText.contains('小学校') || 
                        conversationText.contains('中学校') ||
                        conversationText.contains('学校');
    
    bool hasGradeInfo = RegExp(r'[1-6]年').hasMatch(conversationText);
    
    bool hasTeacherInfo = conversationText.contains('先生') || 
                         conversationText.contains('担任');
    
    bool hasContent = conversationText.length > 50; // 内容が十分にある
    
    return hasSchoolInfo && (hasGradeInfo || hasTeacherInfo) && hasContent;
  }

  /// 明示的に学級通信を生成
  Future<void> generateNewsletter() async {
    if (!_readyToGenerate) {
      debugPrint('[AdkChatProvider] 生成準備が整っていません');
      return;
    }

    try {
      debugPrint('[AdkChatProvider] 明示的な学級通信生成を開始');
      
      // 生成ボタンを非表示にし、処理中状態にする
      _showGenerateButton = false;
      _readyToGenerate = false;
      _safeNotifyListeners();
      
      // 明示的な生成リクエストを送信
      await sendMessage('学級通信を生成してください');
      
    } catch (e) {
      debugPrint('[AdkChatProvider] 明示的生成エラー: $e');
      _errorProvider.setError('学級通信の生成に失敗しました: $e');
      
      // エラー時は生成ボタンを再表示
      _updateGenerateButtonVisibility();
      _safeNotifyListeners();
    }
  }

  /// 学級通信の部分修正を要求
  Future<void> requestModification(String modificationRequest) async {
    if (_generatedHtml == null || _generatedHtml!.isEmpty) {
      debugPrint('[AdkChatProvider] HTML未生成のため修正できません');
      return;
    }

    try {
      debugPrint('[AdkChatProvider] 部分修正リクエスト: $modificationRequest');
      
      // 修正リクエストのメッセージを送信
      String modificationMessage = '生成された学級通信を以下のように修正してください：$modificationRequest';
      await sendMessage(modificationMessage);
      
    } catch (e) {
      debugPrint('[AdkChatProvider] 修正リクエストエラー: $e');
      _errorProvider.setError('修正リクエストに失敗しました: $e');
    }
  }

  /// 修正用のクイックアクションボタンを表示するかどうか
  bool get showModificationOptions => _generatedHtml != null && _generatedHtml!.isNotEmpty && !_isProcessing;

  /// システムメッセージを追加
  void addSystemMessage(String content, {SystemMessageType? type}) {
    final message = MutableChatMessage.system(content, systemMessageType: type);
    _messages.add(message);
    _safeNotifyListeners();
  }

  /// 成功通知メッセージを追加
  void addSuccessMessage(String content) {
    final message = MutableChatMessage.success(content);
    _messages.add(message);
    _safeNotifyListeners();
  }

  /// PDF生成完了メッセージを追加
  void addPdfGeneratedMessage(String content) {
    final message = MutableChatMessage.pdfGenerated(content);
    _messages.add(message);
    _safeNotifyListeners();
  }

  /// Classroom投稿完了メッセージを追加
  void addClassroomPostedMessage(String content) {
    final message = MutableChatMessage.classroomPosted(content);
    _messages.add(message);
    _safeNotifyListeners();
  }

  /// エラーメッセージを追加
  void addErrorMessage(String content) {
    final message = MutableChatMessage.error(content);
    _messages.add(message);
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

  /// WebSocket接続を確立（必要に応じて）
  void _connectWebSocketIfNeeded() {
    if (_sessionId != null && _sessionId!.isNotEmpty && !_artifactWebSocketService.isConnected) {
      debugPrint('[AdkChatProvider] Establishing WebSocket connection for session: $_sessionId');
      _artifactWebSocketService.connect(_sessionId!);
    } else if (_sessionId == null || _sessionId!.isEmpty) {
      debugPrint('[AdkChatProvider] WARNING: Session ID is null or empty, skipping WebSocket connection');
    }
  }

  /// PreviewProviderにHTMLを通知
  void _notifyPreviewProvider(String htmlContent) {
    debugPrint('[AdkChatProvider] _notifyPreviewProvider called with ${htmlContent.length} characters');
    debugPrint('[AdkChatProvider] _previewProvider is null: ${_previewProvider == null}');
    
    if (_previewProvider != null) {
      try {
        _previewProvider!.updateHtmlContent(htmlContent);
        debugPrint('[AdkChatProvider] ✅ HTML passed to PreviewProvider successfully: ${htmlContent.length} characters');
      } catch (e) {
        debugPrint('[AdkChatProvider] ❌ Error notifying PreviewProvider: $e');
      }
    } else {
      debugPrint('[AdkChatProvider] ❌ PreviewProvider is not set, cannot update HTML');
      debugPrint('[AdkChatProvider] 解決方法: home_page.dart で adkChatProvider.setPreviewProvider(previewProvider) を呼び出してください');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _adkService.dispose();
    _artifactWebSocketService.dispose();
    super.dispose();
  }
}
