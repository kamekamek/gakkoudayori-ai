import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/demo_data_service.dart';
/// デモモード用のチャットプロバイダー
class DemoChatProvider extends ChangeNotifier {
  final List<DemoChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isRecording = false;
  String? _generatedHtml;
  Timer? _autoProgressTimer;
  int _currentMessageIndex = 0;
  final DemoDataService _demoDataService = DemoDataService();

  List<DemoChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isRecording => _isRecording;
  String? get generatedHtml => _generatedHtml;

  /// デモモードを開始
  void startDemo() {
    _messages.clear();
    _generatedHtml = null;
    _currentMessageIndex = 0;

    // 最初のメッセージから開始
    _startAutoProgress();
    notifyListeners();
  }

  /// 自動進行タイマーを開始（音声入力から開始）
  void _startAutoProgress() async {
    _autoProgressTimer?.cancel();

    final demoMessages = DemoDataService.getDemoChatMessages();

    // 1秒待機してから音声入力開始
    await Future.delayed(const Duration(seconds: 1));

    // 最初のメッセージは音声入力としてシミュレート
    if (demoMessages.isNotEmpty) {
      final firstMessage = demoMessages[0];
      if (firstMessage.isVoiceInput) {
        await _simulateVoiceInput(firstMessage.text);
      }
      _currentMessageIndex = 1;
    }

    // 次のメッセージを順次表示
    for (int i = 1; i < demoMessages.length; i++) {
      // 2秒待機
      await Future.delayed(const Duration(seconds: 2));

      final message = demoMessages[i];

      _messages.add(message);

      // HTML生成メッセージの場合はHTMLを設定
      if (message.isSystemGenerated) {
        _generatedHtml = DemoDataService.demoNewsletterHtml;
      }
      notifyListeners();
    }
  }

  /// 音声入力をシミュレート
  Future<void> _simulateVoiceInput(String text) async {
    _isRecording = true;
    notifyListeners();

    // 3秒間録音状態をシミュレート
    await Future.delayed(const Duration(seconds: 3));

    _isRecording = false;

    // 音声入力メッセージを追加
    _messages.add(DemoChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: true,
      text: text,
      timestamp: DateTime.now(),
      isVoiceInput: true,
    ));

    notifyListeners();
  }

  /// 手動でメッセージを送信（デモ用）
  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final message = DemoChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: true,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    _messages.add(message);
    notifyListeners();

    // デモ用の自動応答
    _sendAutoResponse(text);
  }

  /// デモ用の自動応答（改良版）
  void _sendAutoResponse(String userMessage) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    final response = DemoDataService.getDummyResponse(userMessage);

    final aiMessage = DemoChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: false,
      text: response,
      timestamp: DateTime.now(),
    );

    _messages.add(aiMessage);
    _isLoading = false;
    notifyListeners();
  }

  /// 録音開始/停止をシミュレート（手動音声入力）
  void toggleRecording() async {
    if (_isRecording) {
      // 録音停止
      _isRecording = false;
      notifyListeners();

      // 録音停止時にサンプルテキストを音声入力として追加
      final voiceMessage = DemoChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isUser: true,
        text: 'タイトルをもう少しかわいらしい感じにしてください。',
        timestamp: DateTime.now(),
        isVoiceInput: true,
      );
      _messages.add(voiceMessage);
      notifyListeners();

      // 自動応答
      _sendAutoResponse(voiceMessage.text);
    } else {
      // 録音開始
      _isRecording = true;
      notifyListeners();
    }
  }

  /// リセット
  void reset() {
    _autoProgressTimer?.cancel();
    _messages.clear();
    _generatedHtml = null;
    _isLoading = false;
    _isRecording = false;
    _currentMessageIndex = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoProgressTimer?.cancel();
    super.dispose();
  }
}
