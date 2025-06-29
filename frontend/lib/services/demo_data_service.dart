import 'dart:async';

/// デモモード用のダミーデータサービス
class DemoDataService {
  static const String demoUserId = 'demo_user_12345';
  static const String demoUserEmail = 'demo@school.example.com';

  /// 音声入力シナリオのテキスト
  static const String speechScenario = '''
日曜日に運動会がありました。
私たちの学年はエイサーを踊りました。
本番に向けてたくさん練習をして、
みんなで力を合わせて
一つの演技を作り上げることができました。
徒競走では一人一人が自分のベストを目指して
一生懸命走り抜くことができました。
本番までたくさんのトラブルがあったんだけど
子供たちが自分たちで解決して、
最後まで頑張り抜くことができました。
''';

  /// ダミーの学級通信HTML
  static const String demoNewsletterHtml = '''
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>学級通信 - 運動会特集</title>
    <style>
        body { font-family: 'Hiragino Sans', 'MS Gothic', sans-serif; margin: 0; padding: 20px; background: #f9f9f9; }
        .newsletter { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; border-bottom: 3px solid #4CAF50; padding-bottom: 20px; margin-bottom: 30px; }
        .title { font-size: 28px; font-weight: bold; color: #2E7D32; margin-bottom: 10px; }
        .date { font-size: 16px; color: #666; }
        .content { line-height: 1.8; }
        .section { margin-bottom: 25px; }
        .section-title { font-size: 20px; font-weight: bold; color: #2E7D32; border-left: 4px solid #4CAF50; padding-left: 10px; margin-bottom: 15px; }
        .highlight { background: linear-gradient(transparent 60%, #FFE082 60%); padding: 2px 4px; }
        .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; }
    </style>
</head>
<body>
    <div class="newsletter">
        <div class="header">
            <div class="title">🏃‍♂️ 学級通信 - 運動会特集 🏃‍♀️</div>
            <div class="date">2024年6月号</div>
        </div>
        
        <div class="content">
            <div class="section">
                <div class="section-title">🎭 エイサーの演技について</div>
                <p>日曜日に運動会がありました。私たちの学年は<span class="highlight">エイサーを踊りました</span>。本番に向けてたくさん練習をして、みんなで力を合わせて一つの演技を作り上げることができました。</p>
                <p>練習期間中は、みんなで協力して振り付けを覚え、心を一つにして踊る大切さを学びました。</p>
            </div>

            <div class="section">
                <div class="section-title">🏃‍♂️ 徒競走での頑張り</div>
                <p>徒競走では<span class="highlight">一人一人が自分のベストを目指して一生懸命走り抜く</span>ことができました。結果にかかわらず、全力で取り組む姿がとても素晴らしかったです。</p>
            </div>

            <div class="section">
                <div class="section-title">💪 困難を乗り越えて</div>
                <p>本番までたくさんのトラブルがあったんだけど、<span class="highlight">子供たちが自分たちで解決して、最後まで頑張り抜く</span>ことができました。</p>
                <p>この経験を通して、仲間と協力することの大切さ、諦めずに取り組むことの素晴らしさを学んだと思います。</p>
            </div>

            <div class="section">
                <div class="section-title">📝 今後の予定</div>
                <p>次回は文化祭に向けて、みんなで一緒に準備を進めていきましょう。運動会で培った協力の心を活かして、素晴らしい発表ができることを期待しています。</p>
            </div>
        </div>

        <div class="footer">
            <p>🏫 ○○小学校 ○年○組担任 ○○先生</p>
            <p>📧 連絡先: demo@school.example.com</p>
        </div>
    </div>
</body>
</html>
''';

  /// ダミーのチャットメッセージリスト（音声入力から開始）
  static List<DemoChatMessage> getDemoChatMessages() {
    return [
      DemoChatMessage(
        id: '1',
        isUser: true,
        text: speechScenario.trim(),
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        isVoiceInput: true,
      ),
      DemoChatMessage(
        id: '2',
        isUser: false, 
        text: '素晴らしい内容ですね！運動会でのエイサーの演技、徒競走での頑張り、そして困難を乗り越えた経験について学級通信を作成いたします。',
        timestamp: DateTime.now().subtract(const Duration(minutes: 9, seconds: 30)),
      ),
      DemoChatMessage(
        id: '3',
        isUser: false,
        text: '学級通信を生成しました！右側のプレビューをご確認ください。内容の修正や追加があればお気軽にお申し付けください。',
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        isSystemGenerated: true,
      ),
    ];
  }

  /// ユーザー入力に対するダミー応答を生成
  static String getDummyResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('修正') || lowerMessage.contains('変更')) {
      return 'かしこまりました。ご指摘の内容を反映して学級通信を修正いたします。';
    } else if (lowerMessage.contains('追加') || lowerMessage.contains('足し')) {
      return '追加の内容を反映いたします。どのような内容を追加されたいでしょうか？';
    } else if (lowerMessage.contains('pdf') || lowerMessage.contains('出力')) {
      return 'PDF出力機能を実行します。プレビューエリアの「PDF出力」ボタンをクリックしてください。';
    } else if (lowerMessage.contains('classroom') || lowerMessage.contains('配信') || lowerMessage.contains('投稿')) {
      return 'Google Classroomへの配信を準備します。「Classroom投稿」ボタンをクリックしてください。';
    } else if (lowerMessage.contains('完成') || lowerMessage.contains('終わり') || lowerMessage.contains('完了')) {
      return '学級通信が完成しました！素晴らしい内容になりましたね。PDF出力やClassroom配信をお試しください。';
    } else {
      return 'ご要望を承りました。学級通信の内容を調整いたします。他にも修正や追加がございましたらお気軽にお申し付けください。';
    }
  }

  /// ダミーのPDF生成処理をシミュレート
  static Future<String> generateDummyPdf() async {
    // 3秒待機してPDF生成をシミュレート
    await Future.delayed(const Duration(seconds: 3));
    return 'https://example.com/demo_newsletter.pdf';
  }

  /// ダミーのClassroom投稿処理をシミュレート
  static Future<String> postToClassroom(String title, String description) async {
    // 2秒待機してClassroom投稿をシミュレート
    await Future.delayed(const Duration(seconds: 2));
    return 'https://classroom.google.com/c/demo_class_123/p/demo_post_456';
  }

  /// ダミーのクラスルーム一覧
  static List<DemoClassroomCourse> getDemoClassrooms() {
    return [
      DemoClassroomCourse(
        id: 'course_1',
        name: '4年1組',
        section: '2024年度',
        studentCount: 28,
      ),
      DemoClassroomCourse(
        id: 'course_2', 
        name: '4年2組',
        section: '2024年度',
        studentCount: 26,
      ),
      DemoClassroomCourse(
        id: 'course_3', 
        name: '総合学習',
        section: '4年生',
        studentCount: 54,
      ),
    ];
  }
}

/// デモ用チャットメッセージクラス
class DemoChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final bool isVoiceInput;
  final bool isSystemGenerated;

  DemoChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.isVoiceInput = false,
    this.isSystemGenerated = false,
  });
}

/// デモ用Classroomコースクラス
class DemoClassroomCourse {
  final String id;
  final String name;
  final String section;
  final int studentCount;

  DemoClassroomCourse({
    required this.id,
    required this.name,
    required this.section,
    required this.studentCount,
  });
}