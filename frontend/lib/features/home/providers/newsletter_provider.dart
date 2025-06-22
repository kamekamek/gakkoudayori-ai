import 'package:flutter/foundation.dart';

/// 学級通信全体の状態管理
class NewsletterProvider extends ChangeNotifier {
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

  // 基本情報の設定
  void updateSchoolInfo({
    String? schoolName,
    String? className, 
    String? teacherName,
  }) {
    if (schoolName != null) _schoolName = schoolName;
    if (className != null) _className = className;
    if (teacherName != null) _teacherName = teacherName;
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
  Future<void> generateNewsletter(String style) async {
    if (_content.isEmpty) {
      updateStatus('❌ 入力内容が空です。まず内容を入力してください。');
      return;
    }

    setGenerating(true);
    setProcessing(true);
    updateStatus('🤖 AI生成中...');

    try {
      // TODO: 実際のAI生成処理を実装
      await Future.delayed(const Duration(seconds: 2)); // 模擬処理

      // 仮のHTML生成
      final html = '''
        <div style="font-family: 'Noto Sans JP', sans-serif; max-width: 800px; margin: 0 auto; padding: 20px;">
          <header style="text-align: center; border-bottom: 2px solid #2196F3; padding-bottom: 10px; margin-bottom: 20px;">
            <h1 style="color: #2196F3; margin: 0;">$_schoolName $_className 学級通信</h1>
          </header>
          
          <main>
            <h2 style="color: #FF9800; display: flex; align-items: center;">
              🏃‍♂️ $_title
            </h2>
            
            <div style="line-height: 1.6; color: #424242;">
              ${_content.replaceAll('\n', '<br>')}
            </div>
          </main>
          
          <footer style="margin-top: 30px; text-align: center; color: #757575; font-size: 14px;">
            <p>$_teacherName</p>
          </footer>
        </div>
      ''';

      updateGeneratedHtml(html);
      updateStatus('🎉 学級通信の生成が完了しました！');
    } catch (e) {
      updateStatus('❌ 生成中にエラーが発生しました: $e');
    } finally {
      setGenerating(false);
      setProcessing(false);
    }
  }
}