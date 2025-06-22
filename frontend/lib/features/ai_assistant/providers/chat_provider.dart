import 'package:flutter/foundation.dart';
import '../../../services/ai_service.dart';
import '../../../services/audio_service.dart';

/// チャットメッセージの型定義
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
  });
}

enum MessageType {
  text,
  voice,
  suggestion,
  system,
}

/// AIチャットアシスタントの状態管理
class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isAiTyping = false;
  bool _isVoiceRecording = false;
  String _currentInput = '';
  
  // サービス
  final AIService _aiService = AIService();
  final AudioService _audioService = AudioService();
  
  // コールバック
  Function(String htmlContent)? onNewsletterGenerated;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isAiTyping => _isAiTyping;
  bool get isVoiceRecording => _isVoiceRecording;
  String get currentInput => _currentInput;

  // 初期化時にウェルカムメッセージを追加
  ChatProvider() {
    _addWelcomeMessage();
    _initializeAudioService();
  }
  
  void _initializeAudioService() {
    _audioService.initializeJavaScriptBridge();
    
    _audioService.setOnRecordingStateChanged((isRecording) {
      setVoiceRecording(isRecording);
    });
    
    _audioService.setOnTranscriptionCompleted((transcript) {
      handleVoiceInput(transcript);
    });
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: 'welcome',
      content: 'こんにちは！今日はどんな学級通信を作りますか？\n\n以下のような内容について教えてください：\n・行事の様子\n・子どもたちの頑張り\n・保護者への連絡事項\n・次回の予定',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.system,
    );
    _messages.add(welcomeMessage);
  }

  // 入力内容の更新
  void updateCurrentInput(String input) {
    _currentInput = input;
    notifyListeners();
  }

  // メッセージの送信
  Future<void> sendMessage(String content, {MessageType type = MessageType.text}) async {
    if (content.trim().isEmpty) return;

    // ユーザーメッセージを追加
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
      type: type,
    );
    _messages.add(userMessage);
    
    // 入力をクリア
    _currentInput = '';
    notifyListeners();

    // AIの応答を生成
    await _generateAiResponse(content);
  }

  // AI応答の生成
  Future<void> _generateAiResponse(String userInput) async {
    _isAiTyping = true;
    notifyListeners();

    try {
      // TODO: 実際のAI API呼び出しを実装
      await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

      String aiResponse = _generateContextualResponse(userInput);

      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.text,
      );

      _messages.add(aiMessage);
    } catch (e) {
      final errorMessage = ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        content: '申し訳ございません。応答の生成中にエラーが発生しました。もう一度お試しください。',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.system,
      );
      _messages.add(errorMessage);
    } finally {
      _isAiTyping = false;
      notifyListeners();
    }
  }

  // 文脈に応じた応答生成（仮実装）
  String _generateContextualResponse(String userInput) {
    final input = userInput.toLowerCase();
    
    if (input.contains('運動会') || input.contains('スポーツ')) {
      return '運動会について詳しく教えてください！\n\n具体的には：\n・子どもたちはどんな競技を頑張りましたか？\n・印象的だった場面はありますか？\n・保護者の方への感謝の気持ちも伝えたいですか？';
    } else if (input.contains('遠足') || input.contains('校外学習')) {
      return '遠足の様子を教えてください！\n\n・どこに行かれましたか？\n・子どもたちの学びや発見はありましたか？\n・楽しかった場面を具体的に教えてください';
    } else if (input.contains('授業参観') || input.contains('参観')) {
      return '授業参観についてお聞かせください！\n\n・どんな授業を見ていただきましたか？\n・子どもたちの成長を感じた場面はありますか？\n・保護者の方に伝えたいことはありますか？';
    } else if (input.contains('お知らせ') || input.contains('連絡')) {
      return 'お知らせ内容について教えてください！\n\n・いつの出来事ですか？\n・保護者の方に何をお伝えしたいですか？\n・準備していただくものはありますか？';
    } else {
      return 'ありがとうございます！もう少し詳しく教えてください。\n\n・いつの出来事ですか？\n・どんな様子でしたか？\n・子どもたちの反応はいかがでしたか？\n\n他にも写真や画像を追加したい場合は、後ほど追加できます。';
    }
  }

  // 音声録音の状態管理
  void setVoiceRecording(bool isRecording) {
    _isVoiceRecording = isRecording;
    notifyListeners();
  }
  
  // 音声録音開始
  Future<bool> startVoiceRecording() async {
    return await _audioService.startRecording();
  }
  
  // 音声録音停止
  Future<bool> stopVoiceRecording() async {
    return await _audioService.stopRecording();
  }

  // 音声認識結果の処理
  Future<void> handleVoiceInput(String transcribedText) async {
    await sendMessage(transcribedText, type: MessageType.voice);
  }

  // 提案の送信
  Future<void> sendSuggestion(String suggestion) async {
    await sendMessage(suggestion, type: MessageType.suggestion);
  }

  // チャットのクリア
  void clearChat() {
    _messages.clear();
    _addWelcomeMessage();
    _currentInput = '';
    _isAiTyping = false;
    _isVoiceRecording = false;
    notifyListeners();
  }

  // 最新のユーザー入力内容を結合して取得
  String getCombinedUserInput() {
    return _messages
        .where((message) => message.isUser && message.type != MessageType.system)
        .map((message) => message.content)
        .join('\n\n');
  }
  
  // 学級通信生成
  Future<void> generateNewsletter() async {
    final combinedInput = getCombinedUserInput();
    if (combinedInput.isEmpty) {
      final errorMessage = ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        content: 'まずはチャットでお話を聞かせてください。内容に基づいて学級通信を作成します。',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.system,
      );
      _messages.add(errorMessage);
      notifyListeners();
      return;
    }
    
    _isAiTyping = true;
    notifyListeners();
    
    try {
      final result = await _aiService.generateNewsletter(
        transcribedText: combinedInput,
        templateType: 'daily_report',
        includeGreeting: true,
        targetAudience: 'parents',
        season: 'auto',
      );
      
      // 生成されたHTMLをプレビューに送信
      onNewsletterGenerated?.call(result.newsletterHtml);
      
      final successMessage = ChatMessage(
        id: 'success_${DateTime.now().millisecondsSinceEpoch}',
        content: '学級通信を生成しました！右側のプレビューでご確認ください。\n\n編集や修正が必要でしたら、お気軽にお申し付けください。',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.system,
      );
      _messages.add(successMessage);
      
    } catch (e) {
      final errorMessage = ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        content: '学級通信の生成中にエラーが発生しました。もう一度お試しください。\n\nエラー: $e',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.system,
      );
      _messages.add(errorMessage);
    } finally {
      _isAiTyping = false;
      notifyListeners();
    }
  }
}