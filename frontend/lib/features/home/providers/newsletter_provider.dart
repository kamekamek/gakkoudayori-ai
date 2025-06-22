import 'package:flutter/foundation.dart';
import '../../../services/adk_agent_service.dart';
import '../../ai_assistant/providers/adk_chat_provider.dart';

/// 学級通信全体の状態管理
class NewsletterProvider extends ChangeNotifier {
  final AdkAgentService adkAgentService;
  final AdkChatProvider adkChatProvider;

  // 基本情報
  String _schoolName = '';
  String _className = '';
  String _teacherName = '';

  // 学級通信の内容
  String _title = '';
  String _content = '';
  String _generatedHtml = '';

  // 処理状態
  bool _isGenerating = false;
  bool _isProcessing = false;
  String _statusMessage = '🎤 音声録音または文字入力で学級通信を作成してください';
  String? _error;

  // Getters
  String get schoolName => _schoolName;
  String get className => _className;
  String get teacherName => _teacherName;
  String get title => _title;
  String get content => _content;
  String get generatedHtml => _generatedHtml;
  bool get isGenerating => _isGenerating;
  bool get isProcessing => _isProcessing;
  String get statusMessage => _statusMessage;
  String? get error => _error;

  NewsletterProvider({
    required this.adkAgentService,
    required this.adkChatProvider,
  });

  // 基本情報の設定
  void updateSchoolInfo({
    String? schoolName,
    String? className,
    String? teacherName,
  }) {
    _schoolName = schoolName ?? _schoolName;
    _className = className ?? _className;
    _teacherName = teacherName ?? _teacherName;
    notifyListeners();
  }

  // 学級通信内容の更新
  void updateContent(String content) {
    _content = content;
    notifyListeners();
  }

  void updateTitle(String title) {
    _title = title;
    notifyListeners();
  }

  void updateGeneratedHtml(String html) {
    _generatedHtml = html;
    notifyListeners();
  }

  // 処理状態の管理
  void setGenerating(bool isGenerating) {
    _isGenerating = isGenerating;
    notifyListeners();
  }

  void setProcessing(bool isProcessing) {
    _isProcessing = isProcessing;
    notifyListeners();
  }

  void updateStatus(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  // 学級通信のリセット
  void resetNewsletter() {
    _title = '';
    _content = '';
    _generatedHtml = '';
    _isGenerating = false;
    _isProcessing = false;
    _statusMessage = '🎤 音声録音または文字入力で学級通信を作成してください';
    notifyListeners();
  }

  // 学級通信の生成
  Future<String?> generateNewsletter() async {
    if (_isGenerating) return null;

    final userId = adkChatProvider.userId;
    final sessionId = adkChatProvider.sessionId;

    if (sessionId == null) {
      _error = 'チャットセッションが開始されていません。';
      notifyListeners();
      return null;
    }

    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final htmlContent = await adkAgentService.generateNewsletter(
        userId: userId,
        sessionId: sessionId,
      );
      return htmlContent;
    } catch (e) {
      _error = '学級通信の生成に失敗しました: $e';
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
}
