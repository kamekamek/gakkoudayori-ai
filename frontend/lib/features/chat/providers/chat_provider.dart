import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/utils/utils.dart';

/// チャットの状態管理
class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  ChatFlowState _flowState = ChatFlowState.initial;
  bool _isProcessing = false;
  bool _isRecording = false;
  String? _currentError;
  
  // AI処理関連
  bool _isGenerating = false;
  double _generationProgress = 0.0;
  
  // 音声関連
  final AudioService _audioService = AudioService();
  
  // チャット設定
  ChatSettings _settings = const ChatSettings();

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  ChatFlowState get flowState => _flowState;
  bool get isProcessing => _isProcessing;
  bool get isRecording => _isRecording;
  String? get currentError => _currentError;
  bool get isGenerating => _isGenerating;
  double get generationProgress => _generationProgress;
  ChatSettings get settings => _settings;
  
  // 計算プロパティ
  bool get hasMessages => _messages.isNotEmpty;
  bool get canSendMessage => !_isProcessing && !_isGenerating;
  ChatMessage? get lastMessage => _messages.isNotEmpty ? _messages.last : null;
  ChatMessage? get lastUserMessage => _messages.reversed.firstWhere(
    (msg) => msg.isUser,
    orElse: () => throw StateError('No user message found'),
  );

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  /// チャット初期化
  Future<void> initialize() async {
    try {
      _audioService.initializeJavaScriptBridge();
      _setupAudioCallbacks();
      
      // 初期メッセージを追加
      _addSystemMessage(
        '学校だよりAIへようこそ！\n'
        '音声入力やテキスト入力で、素敵な学級通信を作成しましょう。\n\n'
        'まず、どのような内容の学級通信を作成したいか教えてください。',
        MessageType.text,
      );
      
      _flowState = ChatFlowState.gatheringContent;
      notifyListeners();
    } catch (e) {
      _currentError = 'チャットの初期化に失敗しました: $e';
      notifyListeners();
    }
  }

  /// 音声録音コールバック設定
  void _setupAudioCallbacks() {
    _audioService.setOnRecordingStateChanged((isRecording) {
      _isRecording = isRecording;
      notifyListeners();
    });

    _audioService.setOnTranscriptionCompleted((text) {
      _handleVoiceInput(text);
    });

    // Note: AudioService doesn't have setOnError method
    // Error handling is done in individual method calls
  }

  /// テキストメッセージ送信
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty || !canSendMessage) return;

    _addUserMessage(text, MessageType.text);
    await _processUserInput(text);
  }

  /// 音声入力開始
  Future<void> startVoiceInput() async {
    if (!canSendMessage) return;
    
    try {
      await _audioService.startRecording();
    } catch (e) {
      _currentError = '音声録音の開始に失敗しました: $e';
      notifyListeners();
    }
  }

  /// 音声入力停止
  Future<void> stopVoiceInput() async {
    try {
      await _audioService.stopRecording();
    } catch (e) {
      _currentError = '音声録音の停止に失敗しました: $e';
      notifyListeners();
    }
  }

  /// 音声入力処理
  void _handleVoiceInput(String transcription) {
    if (transcription.trim().isEmpty) return;
    
    _addUserMessage(transcription, MessageType.voice);
    _processUserInput(transcription);
  }

  /// ユーザー入力処理
  Future<void> _processUserInput(String input) async {
    _setProcessing(true);
    _clearError();

    try {
      await _processBasedOnFlowState(input);
    } catch (e) {
      _currentError = 'メッセージの処理中にエラーが発生しました: $e';
      _addSystemMessage(
        '申し訳ございません。処理中にエラーが発生しました。もう一度お試しください。',
        MessageType.error,
      );
    } finally {
      _setProcessing(false);
    }
  }

  /// フロー状態に基づく処理
  Future<void> _processBasedOnFlowState(String input) async {
    switch (_flowState) {
      case ChatFlowState.initial:
        await _handleInitialInput(input);
        break;
      case ChatFlowState.gatheringContent:
        await _handleContentInput(input);
        break;
      case ChatFlowState.selectingStyle:
        await _handleStyleSelection(input);
        break;
      case ChatFlowState.addingImages:
        await _handleImageInput(input);
        break;
      case ChatFlowState.generating:
        _addSystemMessage(
          '現在、学級通信を生成中です。しばらくお待ちください。',
          MessageType.status,
        );
        break;
      case ChatFlowState.reviewing:
        await _handleReviewInput(input);
        break;
      case ChatFlowState.completed:
        await _handleCompletedInput(input);
        break;
    }
  }

  /// 初期入力処理
  Future<void> _handleInitialInput(String input) async {
    _flowState = ChatFlowState.gatheringContent;
    await _handleContentInput(input);
  }

  /// コンテンツ入力処理
  Future<void> _handleContentInput(String input) async {
    // AIサービスでコンテンツを解析
    // TODO: AIServiceとの統合
    
    _addSystemMessage(
      'ありがとうございます！内容を理解しました。\n'
      'スタイルを選択してください：\n'
      '1. クラシック（伝統的な学校スタイル）\n'
      '2. モダン（現代的でスタイリッシュ）',
      MessageType.options,
      options: ['クラシック', 'モダン'],
    );
    
    _flowState = ChatFlowState.selectingStyle;
  }

  /// スタイル選択処理
  Future<void> _handleStyleSelection(String input) async {
    String selectedStyle = '';
    if (input.contains('クラシック') || input.contains('1')) {
      selectedStyle = 'classic';
    } else if (input.contains('モダン') || input.contains('2')) {
      selectedStyle = 'modern';
    }

    if (selectedStyle.isNotEmpty) {
      _addSystemMessage(
        '${selectedStyle == 'classic' ? 'クラシック' : 'モダン'}スタイルを選択しました。\n'
        '画像を追加しますか？ (はい/いいえ)',
        MessageType.options,
        options: ['はい', 'いいえ'],
      );
      
      _flowState = ChatFlowState.addingImages;
    } else {
      _addSystemMessage(
        '申し訳ございません。選択肢から選んでください。\n'
        '1. クラシック\n'
        '2. モダン',
        MessageType.options,
        options: ['クラシック', 'モダン'],
      );
    }
  }

  /// 画像入力処理
  Future<void> _handleImageInput(String input) async {
    if (input.contains('はい') || input.toLowerCase().contains('yes')) {
      _addSystemMessage(
        '画像を追加できます。以下の方法が選択できます：\n'
        '• ファイルから選択\n'
        '• カメラで撮影\n'
        '• URLから取得\n'
        '• 画像なしで続行',
        MessageType.options,
        options: ['ファイル選択', 'カメラ', 'URL', '画像なしで続行'],
      );
    } else {
      await _startGeneration();
    }
  }

  /// レビュー入力処理
  Future<void> _handleReviewInput(String input) async {
    if (input.contains('OK') || input.contains('良い') || input.contains('完了')) {
      _flowState = ChatFlowState.completed;
      _addSystemMessage(
        '学級通信が完成しました！\n'
        '• PDFダウンロード\n'
        '• Google Classroomに投稿\n'
        '• 編集を続ける',
        MessageType.options,
        options: ['PDF保存', 'Classroom投稿', '編集続行'],
      );
    } else {
      _addSystemMessage(
        '修正内容を反映しています...',
        MessageType.status,
      );
      // TODO: AI修正処理
    }
  }

  /// 完了後入力処理
  Future<void> _handleCompletedInput(String input) async {
    if (input.contains('PDF') || input.contains('保存')) {
      _addSystemMessage(
        'PDFの生成を開始します...',
        MessageType.status,
      );
      // TODO: PDF生成処理
    } else if (input.contains('Classroom') || input.contains('投稿')) {
      _addSystemMessage(
        'Google Classroomへの投稿準備をしています...',
        MessageType.status,
      );
      // TODO: Classroom投稿処理
    } else if (input.contains('編集')) {
      _flowState = ChatFlowState.reviewing;
      _addSystemMessage(
        '編集モードに戻りました。どの部分を修正しますか？',
        MessageType.text,
      );
    }
  }

  /// 学級通信生成開始
  Future<void> _startGeneration() async {
    _setGenerating(true);
    _flowState = ChatFlowState.generating;
    
    _addSystemMessage(
      '学級通信を生成しています...',
      MessageType.status,
    );

    try {
      // TODO: AIServiceで学級通信生成
      // 進捗を更新しながら生成
      for (int i = 0; i <= 100; i += 10) {
        _generationProgress = i / 100.0;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      _addSystemMessage(
        '学級通信が生成されました！\n'
        'プレビューをご確認ください。問題がなければ「完了」とお伝えください。',
        MessageType.options,
        options: ['完了', '修正したい'],
      );
      
      _flowState = ChatFlowState.reviewing;
    } catch (e) {
      _currentError = '学級通信の生成に失敗しました: $e';
      _addSystemMessage(
        '生成中にエラーが発生しました。もう一度お試しください。',
        MessageType.error,
      );
      _flowState = ChatFlowState.gatheringContent;
    } finally {
      _setGenerating(false);
    }
  }

  /// ユーザーメッセージ追加
  void _addUserMessage(String message, MessageType type) {
    final chatMessage = ChatMessage(
      id: AppHelpers.generateId(),
      sender: 'user',
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );
    
    _messages.add(chatMessage);
    notifyListeners();
  }

  /// システムメッセージ追加
  void _addSystemMessage(
    String message,
    MessageType type, {
    List<String>? options,
  }) {
    final chatMessage = ChatMessage(
      id: AppHelpers.generateId(),
      sender: 'ai',
      message: message,
      type: type,
      timestamp: DateTime.now(),
      options: options,
    );
    
    _messages.add(chatMessage);
    notifyListeners();
  }

  /// 処理状態設定
  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  /// 生成状態設定
  void _setGenerating(bool generating) {
    _isGenerating = generating;
    if (!generating) {
      _generationProgress = 0.0;
    }
    notifyListeners();
  }

  /// エラークリア
  void _clearError() {
    _currentError = null;
    notifyListeners();
  }

  /// チャット設定更新
  void updateSettings(ChatSettings settings) {
    _settings = settings;
    notifyListeners();
  }

  /// チャットリセット
  void resetChat() {
    _messages.clear();
    _flowState = ChatFlowState.initial;
    _isProcessing = false;
    _isGenerating = false;
    _generationProgress = 0.0;
    _currentError = null;
    notifyListeners();
    
    // 再初期化
    initialize();
  }

  /// 特定メッセージ削除
  void removeMessage(String messageId) {
    _messages.removeWhere((msg) => msg.id == messageId);
    notifyListeners();
  }

  /// メッセージ編集
  void editMessage(String messageId, String newContent) {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(message: newContent);
      notifyListeners();
    }
  }
}