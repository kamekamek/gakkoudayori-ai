/// モック用のサンプルデータ
class MockSampleData {
  // 教員向けチャット会話例のサンプル
  static const List<MockChatExample> chatExamples = [
    MockChatExample(
      userInput: "今度運動会があるので、保護者の皆さんに連絡事項をお知らせしたいです",
      aiResponse: """運動会の学級通信作成ですね！以下の内容について教えてください：

1. 運動会の開催日時と場所
2. 当日の持ち物や服装の注意点
3. 保護者の皆様へのお願い事項
4. 雨天時の対応について

どの内容から始めましょうか？""",
    ),
    
    MockChatExample(
      userInput: "来週の遠足について保護者に連絡したいです。行き先は動物園で、お弁当持参です",
      aiResponse: """遠足の学級通信を作成いたします。動物園への遠足ですね！

以下の内容で進めさせていただきます：
- 日時：来週（具体的な日付をお教えください）
- 行き先：動物園
- お弁当：持参

他に以下の点についてもお聞かせください：
- 集合時間と場所
- 服装や持ち物の指定
- 雨天時の対応
- 緊急連絡先

まずは日時から確認させてください。""",
    ),
    
    MockChatExample(
      userInput: "学習発表会の練習が始まったので、保護者に協力をお願いしたいです",
      aiResponse: """学習発表会に向けた保護者への協力依頼の学級通信を作成させていただきます。

以下の内容について詳しく教えてください：
1. 学習発表会の日程
2. 発表内容（劇、合唱、楽器演奏など）
3. 保護者にお願いしたい具体的な協力内容
4. 衣装や小道具について
5. 練習期間中の家庭でのサポート

どちらから詳しくお聞かせいただけますでしょうか？""",
    ),
  ];

  // 学級通信HTMLテンプレート（クラシックスタイル）
  static const String classicNewsletterTemplate = '''
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>学級通信</title>
    <style>
        body {
            font-family: 'Noto Sans JP', sans-serif;
            line-height: 1.6;
            margin: 20px;
            color: #333;
            background-color: #fff;
        }
        .header {
            text-align: center;
            border-bottom: 3px solid #2E7D32;
            padding-bottom: 15px;
            margin-bottom: 20px;
        }
        .title {
            font-size: 28px;
            font-weight: bold;
            color: #2E7D32;
            margin: 0;
        }
        .school-info {
            font-size: 14px;
            color: #666;
            margin-top: 8px;
        }
        .date {
            text-align: right;
            font-size: 14px;
            color: #666;
            margin-bottom: 20px;
        }
        .section {
            margin-bottom: 25px;
        }
        .section-title {
            font-size: 18px;
            font-weight: bold;
            color: #2E7D32;
            border-left: 4px solid #2E7D32;
            padding-left: 10px;
            margin-bottom: 10px;
        }
        .content {
            font-size: 14px;
            line-height: 1.8;
            margin-left: 15px;
        }
        .highlight {
            background-color: #E8F5E8;
            padding: 10px;
            border-radius: 5px;
            margin: 10px 0;
        }
        .important {
            color: #D32F2F;
            font-weight: bold;
        }
        ul, ol {
            margin-left: 20px;
        }
        li {
            margin-bottom: 5px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1 class="title">学級通信「みんなでがんばろう」</h1>
        <div class="school-info">〇〇小学校 1年1組 担任：田中先生</div>
    </div>

    <div class="date">令和6年{{MONTH}}月{{DAY}}日</div>

    <div class="section">
        <h2 class="section-title">運動会について</h2>
        <div class="content">
            <p>いよいよ来週の土曜日（{{EVENT_DATE}}）は運動会です！子どもたちは毎日一生懸命練習に取り組んでいます。</p>
            
            <div class="highlight">
                <h3>当日のお願い</h3>
                <ul>
                    <li><span class="important">集合時間：</span>午前8時30分（通常より30分早いです）</li>
                    <li><span class="important">服装：</span>体操服、赤白帽子、運動靴</li>
                    <li><span class="important">持ち物：</span>水筒、タオル、着替え</li>
                    <li><span class="important">お弁当：</span>不要（午前中のみの開催のため）</li>
                </ul>
            </div>

            <p>雨天の場合は月曜日に延期となります。当日午前6時にメール配信でお知らせいたします。</p>
        </div>
    </div>

    <div class="section">
        <h2 class="section-title">保護者の皆様へ</h2>
        <div class="content">
            <p>運動会では、お子様の成長した姿をぜひご覧ください。応援席からの温かい声援をよろしくお願いいたします。</p>
            <p>また、写真撮影の際は他のお子様が写らないよう、ご配慮をお願いいたします。</p>
        </div>
    </div>

    <div class="section">
        <h2 class="section-title">来週の予定</h2>
        <div class="content">
            <ul>
                <li>月曜日：運動会予備日</li>
                <li>火曜日：振替休日</li>
                <li>水曜日：通常授業</li>
                <li>木曜日：図書館見学</li>
                <li>金曜日：身体測定</li>
            </ul>
        </div>
    </div>
</body>
</html>
''';

  // 学級通信HTMLテンプレート（モダンスタイル）
  static const String modernNewsletterTemplate = '''
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>学級通信</title>
    <style>
        body {
            font-family: 'Noto Sans JP', sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .newsletter {
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            overflow: hidden;
            max-width: 800px;
            margin: 0 auto;
        }
        .header {
            background: linear-gradient(135deg, #FF6B6B, #4ECDC4);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .title {
            font-size: 32px;
            font-weight: bold;
            margin: 0 0 10px 0;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .school-info {
            font-size: 16px;
            opacity: 0.9;
        }
        .content-wrapper {
            padding: 30px;
        }
        .date-badge {
            background: #FF6B6B;
            color: white;
            padding: 8px 20px;
            border-radius: 20px;
            display: inline-block;
            font-weight: bold;
            margin-bottom: 20px;
        }
        .section {
            margin-bottom: 30px;
            background: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
            border-left: 5px solid #4ECDC4;
        }
        .section-title {
            font-size: 20px;
            font-weight: bold;
            color: #2c3e50;
            margin: 0 0 15px 0;
            display: flex;
            align-items: center;
        }
        .section-title::before {
            content: "📚";
            margin-right: 10px;
            font-size: 24px;
        }
        .highlight-box {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            padding: 20px;
            border-radius: 10px;
            margin: 15px 0;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 15px 0;
        }
        .info-item {
            background: white;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #FF6B6B;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .info-label {
            font-weight: bold;
            color: #FF6B6B;
            font-size: 14px;
        }
        .info-value {
            font-size: 16px;
            margin-top: 5px;
        }
        .schedule-list {
            list-style: none;
            padding: 0;
        }
        .schedule-item {
            background: white;
            margin: 10px 0;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #4ECDC4;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .day {
            font-weight: bold;
            color: #4ECDC4;
        }
        .activity {
            margin-top: 5px;
        }
    </style>
</head>
<body>
    <div class="newsletter">
        <div class="header">
            <h1 class="title">✨ みんなでがんばろう ✨</h1>
            <div class="school-info">〇〇小学校 1年1組 担任：田中先生</div>
        </div>

        <div class="content-wrapper">
            <div class="date-badge">📅 令和6年{{MONTH}}月{{DAY}}日</div>

            <div class="section">
                <h2 class="section-title">🏃‍♂️ 運動会について</h2>
                <p>いよいよ来週の土曜日（{{EVENT_DATE}}）は運動会です！子どもたちは毎日一生懸命練習に取り組んでいます。</p>
                
                <div class="highlight-box">
                    <h3 style="margin-top: 0;">📋 当日のお願い</h3>
                    <div class="info-grid">
                        <div class="info-item">
                            <div class="info-label">⏰ 集合時間</div>
                            <div class="info-value">午前8時30分<br><small>（通常より30分早いです）</small></div>
                        </div>
                        <div class="info-item">
                            <div class="info-label">👕 服装</div>
                            <div class="info-value">体操服、赤白帽子<br>運動靴</div>
                        </div>
                        <div class="info-item">
                            <div class="info-label">🎒 持ち物</div>
                            <div class="info-value">水筒、タオル<br>着替え</div>
                        </div>
                        <div class="info-item">
                            <div class="info-label">🍱 お弁当</div>
                            <div class="info-value">不要<br><small>（午前中のみ開催）</small></div>
                        </div>
                    </div>
                </div>

                <p>☔ 雨天の場合は月曜日に延期となります。当日午前6時にメール配信でお知らせいたします。</p>
            </div>

            <div class="section">
                <h2 class="section-title">👨‍👩‍👧‍👦 保護者の皆様へ</h2>
                <p>運動会では、お子様の成長した姿をぜひご覧ください。応援席からの温かい声援をよろしくお願いいたします。</p>
                <p>📸 また、写真撮影の際は他のお子様が写らないよう、ご配慮をお願いいたします。</p>
            </div>

            <div class="section">
                <h2 class="section-title">📅 来週の予定</h2>
                <ul class="schedule-list">
                    <li class="schedule-item">
                        <div class="day">月曜日</div>
                        <div class="activity">🏃‍♂️ 運動会予備日</div>
                    </li>
                    <li class="schedule-item">
                        <div class="day">火曜日</div>
                        <div class="activity">🏠 振替休日</div>
                    </li>
                    <li class="schedule-item">
                        <div class="day">水曜日</div>
                        <div class="activity">📚 通常授業</div>
                    </li>
                    <li class="schedule-item">
                        <div class="day">木曜日</div>
                        <div class="activity">📖 図書館見学</div>
                    </li>
                    <li class="schedule-item">
                        <div class="day">金曜日</div>
                        <div class="activity">📏 身体測定</div>
                    </li>
                </ul>
            </div>
        </div>
    </div>
</body>
</html>
''';

  // 音声認識のダミー結果
  static const List<String> voiceRecognitionSamples = [
    "今度遠足があるので保護者に連絡事項をお知らせしたいです",
    "運動会の練習が始まったので応援をお願いしたいです",
    "学習発表会に向けて家庭でのサポートをお願いしたいです",
    "来週の授業参観についてお知らせしたいです",
    "クラスの様子を保護者に報告したいです",
  ];

  // Classroom投稿のダミー情報
  static const MockClassroomPost classroomPostSample = MockClassroomPost(
    title: "学級通信「みんなでがんばろう」- 運動会について",
    content: "運動会に向けた大切なお知らせです。詳細をご確認ください。",
    attachmentName: "学級通信_1年1組_2024年10月15日.pdf",
    postDate: "2024年10月15日 14:30",
  );

  // 動的にHTMLテンプレートを生成
  static String generateNewsletterHtml({
    required String style, // 'classic' or 'modern'
    String? month,
    String? day,
    String? eventDate,
    String? schoolName,
    String? className,
    String? teacherName,
  }) {
    final template = style == 'modern' ? modernNewsletterTemplate : classicNewsletterTemplate;
    
    return template
        .replaceAll('{{MONTH}}', month ?? '10')
        .replaceAll('{{DAY}}', day ?? '15')
        .replaceAll('{{EVENT_DATE}}', eventDate ?? '10月21日（土）')
        .replaceAll('〇〇小学校', schoolName ?? '〇〇小学校')
        .replaceAll('1年1組', className ?? '1年1組')
        .replaceAll('田中先生', teacherName ?? '田中先生');
  }

  // ランダムな会話例を取得
  static MockChatExample getRandomChatExample() {
    final examples = chatExamples..shuffle();
    return examples.first;
  }

  // ランダムな音声認識結果を取得
  static String getRandomVoiceRecognitionSample() {
    final samples = List.from(voiceRecognitionSamples)..shuffle();
    return samples.first;
  }
}

/// チャット会話例のモデル
class MockChatExample {
  final String userInput;
  final String aiResponse;

  const MockChatExample({
    required this.userInput,
    required this.aiResponse,
  });
}

/// Classroom投稿のモックモデル
class MockClassroomPost {
  final String title;
  final String content;
  final String attachmentName;
  final String postDate;

  const MockClassroomPost({
    required this.title,
    required this.content,
    required this.attachmentName,
    required this.postDate,
  });
}