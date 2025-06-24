import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'adk_agent_service.dart';
import '../mock/sample_data.dart';

/// AdkAgentServiceのモック実装（デモ用）
class AdkAgentServiceMock extends AdkAgentService {
  static const String _mockSessionId = 'mock_session_12345';
  static int _messageCounter = 0;
  
  final List<ChatMessage> _sessionMessages = [];
  String? _currentGeneratedHtml;
  int _conversationStep = 0;
  String _currentTopic = '';
  bool _isHtmlGenerated = false;
  
  @override
  Future<AdkChatResponse> sendChatMessage({
    required String message,
    required String userId,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // リアルな遅延
    
    // ユーザーメッセージを保存
    _sessionMessages.add(ChatMessage(
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    ));
    
    // モック応答を生成
    final response = _generateMockResponse(message);
    
    // AIレスポンスを保存
    _sessionMessages.add(ChatMessage(
      role: 'assistant',
      content: response,
      timestamp: DateTime.now(),
    ));
    
    return AdkChatResponse(
      message: response,
      sessionId: sessionId ?? _mockSessionId,
      eventType: 'chat_response',
      htmlOutput: _shouldGenerateHtml(message) ? _currentGeneratedHtml : null,
      metadata: metadata,
    );
  }

  @override
  Stream<AdkStreamEvent> streamChatSSE({
    required String message,
    required String userId,
    String? sessionId,
  }) async* {
    debugPrint('[MockService] Starting stream for message: "$message"');
    
    final sessionIdToUse = sessionId ?? _mockSessionId;
    
    // ユーザーメッセージを保存
    _sessionMessages.add(ChatMessage(
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    ));
    
    // セッションIDを最初に送信
    yield AdkStreamEvent(
      sessionId: sessionIdToUse,
      type: 'session_start',
      data: sessionIdToUse,
    );
    
    // モック応答を段階的に配信
    final response = _generateMockResponse(message);
    final chunks = _splitIntoChunks(response, 10);
    
    for (int i = 0; i < chunks.length; i++) {
      await Future.delayed(Duration(milliseconds: 100 + (i * 50)));
      
      yield AdkStreamEvent(
        sessionId: sessionIdToUse,
        type: 'text',
        data: chunks[i],
      );
    }
    
    // AIレスポンスを保存
    _sessionMessages.add(ChatMessage(
      role: 'assistant',
      content: response,
      timestamp: DateTime.now(),
    ));
    
    // HTMLコンテンツが必要な場合
    if (_shouldGenerateHtml(message)) {
      await Future.delayed(const Duration(milliseconds: 300));
      
      yield AdkStreamEvent(
        sessionId: sessionIdToUse,
        type: 'text',
        data: '\n\n学級通信を生成しています...',
      );
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      _currentGeneratedHtml = _generateMockHtml();
      _isHtmlGenerated = true; // HTML生成完了フラグ
      
      yield AdkStreamEvent(
        sessionId: sessionIdToUse,
        type: 'complete',
        data: _currentGeneratedHtml!,
      );
    }
    
    debugPrint('[MockService] Stream completed');
  }

  @override
  Future<NewsletterGenerationResponse> startNewsletterGeneration({
    required String initialRequest,
    required String userId,
    String? sessionId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    _currentGeneratedHtml = _generateMockHtml();
    
    return NewsletterGenerationResponse(
      sessionId: sessionId ?? _mockSessionId,
      status: 'completed',
      htmlContent: _currentGeneratedHtml,
      jsonStructure: {
        'title': '学級通信「みんなでがんばろう」',
        'date': '2024年10月15日',
        'sections': ['運動会について', '保護者の皆様へ', '来週の予定']
      },
      messages: List.from(_sessionMessages),
    );
  }

  @override
  Future<String> generateNewsletter({
    required String userId,
    required String sessionId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    _currentGeneratedHtml = _generateMockHtml();
    return _currentGeneratedHtml!;
  }

  @override
  Future<SessionInfo> getSession(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    return SessionInfo(
      sessionId: sessionId,
      userId: 'mock_user',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now(),
      messages: List.from(_sessionMessages),
      status: 'active',
      agentState: {
        'current_agent': 'orchestrator',
        'context': {
          'school_name': '〇〇小学校',
          'class_name': '1年1組',
          'teacher_name': '田中先生',
        }
      },
    );
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _sessionMessages.clear();
    _currentGeneratedHtml = null;
    _conversationStep = 0;
    _currentTopic = '';
    _isHtmlGenerated = false;
  }

  @override
  void dispose() {
    // モックなので何もしない
  }

  /// メッセージに応じてモック応答を生成（段階的な対話）
  String _generateMockResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    // HTML生成後の修正対話
    if (_isHtmlGenerated) {
      return _generatePostGenerationResponse(message);
    }
    
    // 最初のメッセージでトピックを決定
    if (_conversationStep == 0) {
      if (lowerMessage.contains('運動会') || lowerMessage.contains('うんどうかい')) {
        _currentTopic = '運動会';
        _conversationStep = 1;
        return """運動会の学級通信作成ですね！子どもたちが楽しみにしている大切なイベントですね。

まず、運動会の基本情報について教えてください：
・開催日時はいつですか？
・雨天の場合の対応はどうなりますか？""";
      }
      
      if (lowerMessage.contains('遠足') || lowerMessage.contains('えんそく')) {
        _currentTopic = '遠足';
        _conversationStep = 1;
        return """遠足の学級通信を作成いたします！子どもたちがワクワクしているイベントですね。

遠足の詳細について教えてください：
・行き先はどちらですか？
・出発時間と帰校予定時間を教えてください。""";
      }
      
      if (lowerMessage.contains('学習発表会') || lowerMessage.contains('発表会')) {
        _currentTopic = '学習発表会';
        _conversationStep = 1;
        return """学習発表会の学級通信作成ですね！子どもたちの成長を披露する素晴らしい機会ですね。

発表会について詳しく教えてください：
・開催日時と会場はどちらですか？
・クラスではどのような発表を予定していますか？""";
      }
    }
    
    // トピック別の段階的対話
    if (_currentTopic == '運動会') {
      return _generateSportsEventResponse();
    } else if (_currentTopic == '遠足') {
      return _generateFieldTripResponse();
    } else if (_currentTopic == '学習発表会') {
      return _generatePresentationResponse();
    }
    
    // 生成要求の検出
    if (lowerMessage.contains('生成') || lowerMessage.contains('作成') || 
        lowerMessage.contains('つくって') || lowerMessage.contains('作って') ||
        lowerMessage.contains('お願いします') || lowerMessage.contains('よろしく')) {
      return """承知いたしました！これまでお聞かせいただいた内容をもとに、保護者の皆様にわかりやすい学級通信を作成いたします。

✨ 学級通信を生成しています...
📝 レイアウトを調整中...
🎨 デザインを適用中...

少々お待ちください。右側のプレビューエリアに表示されます！""";
    }
    
    // 一般的な応答
    final responses = [
      """ありがとうございます！その詳細について、もう少し具体的に教えていただけますか？

保護者の皆様により正確な情報をお伝えできるよう、お聞かせください。""",
      
      """とても大切な情報ですね！

他にも保護者の皆様にお伝えしておきたいことはありますか？""",
      
      """なるほど、よく分かりました。

準備が整いましたら「生成してください」とお声がけください。学級通信を作成いたします！""",
    ];
    
    final random = Random();
    return responses[random.nextInt(responses.length)];
  }

  /// 運動会関連の段階的応答
  String _generateSportsEventResponse() {
    _conversationStep++;
    
    switch (_conversationStep) {
      case 2:
        return """ありがとうございます！運動会の日程について承知いたしました。

次に、当日の詳細について教えてください：
・子どもたちの服装（体操服の指定など）
・持ち物で特に注意すべきもの
・保護者の皆様の観覧について""";
      
      case 3:
        return """当日の準備についてよく分かりました！

最後に以下についてお聞かせください：
・応援の際の注意事項
・写真撮影のルール
・その他、保護者の皆様へのお願い事項

情報が整いましたら、学級通信を生成いたします！""";
      
      default:
        return """情報をありがとうございます！

運動会についての詳細が揃いました。「生成してください」とお声がけいただければ、保護者の皆様向けの学級通信を作成いたします。""";
    }
  }

  /// 遠足関連の段階的応答
  String _generateFieldTripResponse() {
    _conversationStep++;
    
    switch (_conversationStep) {
      case 2:
        return """遠足の基本情報をありがとうございます！

続いて、準備について教えてください：
・お弁当の注意事項（アレルギー対応など）
・服装の指定（動きやすい服装、帽子など）
・持参すべき持ち物""";
      
      case 3:
        return """準備についてよく分かりました！

安全面について最後に確認させてください：
・緊急時の連絡方法
・体調不良時の対応
・その他、保護者の皆様へのお願い

これで学級通信の作成準備が整います！""";
      
      default:
        return """遠足の詳細情報をありがとうございました！

すべての情報が揃いましたので、「生成してください」とお声がけいただければ学級通信を作成いたします。""";
    }
  }

  /// 学習発表会関連の段階的応答
  String _generatePresentationResponse() {
    _conversationStep++;
    
    switch (_conversationStep) {
      case 2:
        return """発表会の概要をありがとうございます！

保護者の皆様の観覧について教えてください：
・座席の指定や予約の必要性
・開場時間と注意事項
・写真・ビデオ撮影のルール""";
      
      case 3:
        return """観覧についてよく分かりました！

最後に準備について確認させてください：
・子どもたちの衣装や準備物
・家庭でのサポートのお願い
・当日のスケジュール

情報が整い次第、学級通信を作成いたします！""";
      
      default:
        return """学習発表会についての詳細をありがとうございました！

すべての準備が整いましたので、「生成してください」とお声がけいただければ素敵な学級通信を作成いたします。""";
    }
  }

  /// HTMLコンテンツを生成すべきかチェック
  bool _shouldGenerateHtml(String message) {
    if (_isHtmlGenerated) return false; // すでに生成済みの場合は再生成しない
    
    final lowerMessage = message.toLowerCase();
    return lowerMessage.contains('生成') || 
           lowerMessage.contains('作成') || 
           lowerMessage.contains('つくって') || 
           lowerMessage.contains('作って') ||
           lowerMessage.contains('お願いします') || 
           lowerMessage.contains('よろしく');
  }

  /// HTML生成後の修正対話を処理
  String _generatePostGenerationResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    // タイトル変更
    if (lowerMessage.contains('タイトル') || lowerMessage.contains('題名')) {
      return """タイトルの修正ですね！承知いたしました。

どのようなタイトルに変更いたしましょうか？例えば：
・「運動会のお知らせ」
・「みんなでがんばろう！運動会」
・「令和6年度 運動会について」

ご希望のタイトルを教えてください。すぐに反映いたします。""";
    }
    
    // 文章の修正
    if (lowerMessage.contains('文章') || lowerMessage.contains('内容') || lowerMessage.contains('修正')) {
      return """内容の修正ですね！

具体的にどの部分を修正いたしましょうか？
・持ち物の詳細を追加
・時間の変更
・注意事項の追加
・文章の表現を変更

修正したい内容を詳しく教えてください。リアルタイムで反映いたします。""";
    }
    
    // 色やデザインの変更
    if (lowerMessage.contains('色') || lowerMessage.contains('デザイン') || lowerMessage.contains('見た目')) {
      return """デザインの調整ですね！

以下のような変更が可能です：
・文字色の変更（青、緑、赤など）
・背景色の調整
・フォントサイズの変更
・レイアウトスタイルの変更（クラシック⇔モダン）

どのような変更をご希望でしょうか？""";
    }
    
    // 項目の追加
    if (lowerMessage.contains('追加') || lowerMessage.contains('入れて') || lowerMessage.contains('加えて')) {
      return """項目の追加ですね！承知いたしました。

どのような内容を追加いたしましょうか？
・緊急連絡先
・駐車場の案内
・昼食の詳細
・写真撮影のお願い
・その他のお知らせ

追加したい内容を具体的に教えてください。""";
    }
    
    // 削除要求
    if (lowerMessage.contains('削除') || lowerMessage.contains('消して') || lowerMessage.contains('取って')) {
      return """項目の削除ですね！

どの部分を削除いたしましょうか？不要な項目を具体的に教えてください。すぐに反映いたします。""";
    }
    
    // 一般的な修正対応
    return """学級通信の修正についてお手伝いいたします！

以下のような修正が可能です：
📝 **内容の修正**: 文章の追加・削除・変更
🎨 **デザイン変更**: 色、フォント、レイアウト
📋 **項目の調整**: 新しい項目の追加や不要な項目の削除
📅 **日時の変更**: 開催日時や締切日の修正

どのような修正をご希望でしょうか？具体的に教えていただければ、すぐに反映いたします。""";
  }

  /// モックHTMLコンテンツを生成
  String _generateMockHtml() {
    final random = Random();
    final isModern = random.nextBool();
    final style = isModern ? 'modern' : 'classic';
    
    final now = DateTime.now();
    
    return MockSampleData.generateNewsletterHtml(
      style: style,
      month: now.month.toString(),
      day: now.day.toString(),
      eventDate: _getNextEventDate(),
      schoolName: '〇〇小学校',
      className: '1年1組', 
      teacherName: '田中先生',
    );
  }

  /// 次のイベント日を取得
  String _getNextEventDate() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    
    return '${nextWeek.month}月${nextWeek.day}日（${weekdays[nextWeek.weekday - 1]}）';
  }

  /// テキストをチャンクに分割
  List<String> _splitIntoChunks(String text, int wordsPerChunk) {
    final words = text.split('');
    final chunks = <String>[];
    
    for (int i = 0; i < words.length; i += wordsPerChunk) {
      final end = (i + wordsPerChunk < words.length) ? i + wordsPerChunk : words.length;
      chunks.add(words.sublist(i, end).join(''));
    }
    
    return chunks;
  }

  /// 便利メソッド：ランダムチャット例を取得
  static MockChatExample getRandomChatExample() {
    return MockSampleData.getRandomChatExample();
  }

  /// 便利メソッド：会話をリセット
  void clearSession() {
    _sessionMessages.clear();
    _currentGeneratedHtml = null;
    _messageCounter = 0;
    _conversationStep = 0;
    _currentTopic = '';
    _isHtmlGenerated = false;
  }

  /// 便利メソッド：現在のHTMLコンテンツを取得
  String? get currentHtmlContent => _currentGeneratedHtml;

  /// 便利メソッド：現在のメッセージ一覧を取得
  List<ChatMessage> get currentMessages => List.from(_sessionMessages);
}