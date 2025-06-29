import 'package:flutter/material.dart';
import '../../../services/demo_data_service.dart';

/// デモモード用のプレビュープロバイダー
class DemoPreviewProvider extends ChangeNotifier {
  String _htmlContent = '';
  bool _isLoading = false;
  String _currentMode = 'preview'; // 'preview', 'edit', 'printView'
  
  // 編集可能な内容を保持
  String _title = '🏃‍♂️ 学級通信 - 運動会特集 🏃‍♀️';
  String _date = '2024年6月号';
  String _section1Title = '🎭 エイサーの演技について';
  String _section1Content = '日曜日に運動会がありました。私たちの学年は エイサーを踊りました。本番に向けてたくさん練習をして、みんなで力を合わせて一つの演技を作り上げることができました。\n\n練習期間中は、みんなで協力して振り付けを覚え、心を一つにして踊る大切さを学びました。';
  String _section2Title = '🏃‍♂️ 徒競走での頑張り';
  String _section2Content = '徒競走では 一人一人が自分のベストを目指して一生懸命走り抜く ことができました。結果にかかわらず、全力で取り組む姿がとても素晴らしかったです。';
  String _section3Title = '💪 困難を乗り越えて';
  String _section3Content = '本番までたくさんのトラブルがあったんだけど、 子供たちが自分たちで解決して、最後まで頑張り抜く ことができました。\n\nこの経験を通して、仲間と協力することの大切さ、諦めずに取り組むことの素晴らしさを学んだと思います。';
  String _section4Title = '📝 今後の予定';
  String _section4Content = '次回は文化祭に向けて、みんなで一緒に準備を進めていきましょう。運動会で培った協力の心を活かして、素晴らしい発表ができることを期待しています。';
  String _schoolInfo = '🏫 ○○小学校 ○年○組担任 ○○先生';
  String _contactInfo = '📧 連絡先: demo@school.example.com';

  String get htmlContent => _htmlContent;
  bool get isLoading => _isLoading;
  String get currentMode => _currentMode;
  
  // ゲッター
  String get title => _title;
  String get date => _date;
  String get section1Title => _section1Title;
  String get section1Content => _section1Content;
  String get section2Title => _section2Title;
  String get section2Content => _section2Content;
  String get section3Title => _section3Title;
  String get section3Content => _section3Content;
  String get section4Title => _section4Title;
  String get section4Content => _section4Content;
  String get schoolInfo => _schoolInfo;
  String get contactInfo => _contactInfo;

  /// プレビューモードを設定
  void setMode(String mode) {
    _currentMode = mode;
    notifyListeners();
  }
  
  /// テキスト更新メソッド
  void updateTitle(String newTitle) {
    _title = newTitle;
    notifyListeners();
  }
  
  void updateDate(String newDate) {
    _date = newDate;
    notifyListeners();
  }
  
  void updateSection1Title(String newTitle) {
    _section1Title = newTitle;
    notifyListeners();
  }
  
  void updateSection1Content(String newContent) {
    _section1Content = newContent;
    notifyListeners();
  }
  
  void updateSection2Title(String newTitle) {
    _section2Title = newTitle;
    notifyListeners();
  }
  
  void updateSection2Content(String newContent) {
    _section2Content = newContent;
    notifyListeners();
  }
  
  void updateSection3Title(String newTitle) {
    _section3Title = newTitle;
    notifyListeners();
  }
  
  void updateSection3Content(String newContent) {
    _section3Content = newContent;
    notifyListeners();
  }
  
  void updateSection4Title(String newTitle) {
    _section4Title = newTitle;
    notifyListeners();
  }
  
  void updateSection4Content(String newContent) {
    _section4Content = newContent;
    notifyListeners();
  }
  
  void updateSchoolInfo(String newInfo) {
    _schoolInfo = newInfo;
    notifyListeners();
  }
  
  void updateContactInfo(String newInfo) {
    _contactInfo = newInfo;
    notifyListeners();
  }

  /// HTML内容を更新
  void updateHtmlContent(String html) {
    _htmlContent = html;
    notifyListeners();
  }

  /// デモ用のHTML内容を設定
  void setDemoContent() {
    _htmlContent = DemoDataService.demoNewsletterHtml;
    notifyListeners();
  }

  /// PDF生成をシミュレート
  Future<String> generatePdf() async {
    _isLoading = true;
    notifyListeners();

    try {
      final pdfUrl = await DemoDataService.generateDummyPdf();
      return pdfUrl;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Classroom投稿をシミュレート
  Future<String> postToClassroom(String title, String description) async {
    _isLoading = true;
    notifyListeners();

    try {
      final postUrl = await DemoDataService.postToClassroom(title, description);
      return postUrl;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 印刷をシミュレート
  void printNewsletter() {
    // デモ用印刷処理
    debugPrint('🖨️ 印刷実行');
  }

  /// ダウンロードをシミュレート
  void downloadNewsletter() {
    // デモ用ダウンロード処理
    debugPrint('📥 ダウンロード実行');
  }
}