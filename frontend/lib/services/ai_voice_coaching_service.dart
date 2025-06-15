import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 🚀 Revolutionary Innovation 2: AI音声コーチング機能
/// リアルタイム音声入力中のAI提案・ガイダンスシステム
class AIVoiceCoachingService {
  static final AIVoiceCoachingService _instance = AIVoiceCoachingService._internal();
  factory AIVoiceCoachingService() => _instance;
  AIVoiceCoachingService._internal();

  // 音声コーチング状態
  bool _isCoachingActive = false;
  StreamController<CoachingMessage>? _messageController;
  Timer? _analysisTimer;
  
  // 学習データ
  Map<String, dynamic> _userProfile = {};
  final List<String> _conversationHistory = [];
  
  // コーチングメッセージタイプ
  final Map<String, List<String>> _coachingMessages = {
    'encouragement': [
      '順調に話せていますね！',
      'とても分かりやすい説明です',
      'いい感じで進んでいます',
      '聞き取りやすいペースですね',
    ],
    'suggestion': [
      'もう少し具体的に説明してみませんか？',
      '写真について詳しく話すと良いでしょう',
      '子どもたちの様子を追加すると魅力的です',
      '保護者の方へのメッセージも入れてみませんか？',
    ],
    'structure': [
      '見出しを付けると読みやすくなります',
      '日時や場所を明記すると親切です',
      '箇条書きで整理すると伝わりやすいです',
      '感想や振り返りを入れると良いでしょう',
    ],
    'clarification': [
      'いつの出来事か明確にしましょう',
      'どの学年の話か教えてください',
      'どんな活動だったか詳しく聞かせてください',
      '結果や成果はどうでしたか？',
    ],
    'completion': [
      'そろそろまとめに入りませんか？',
      '伝えたいことは全て話せましたか？',
      '最後に保護者への感謝を入れてみませんか？',
      '来月の予定も触れてみませんか？',
    ],
  };

  /// 🎯 音声コーチング開始
  Future<void> startCoaching() async {
    if (_isCoachingActive) return;
    
    _isCoachingActive = true;
    _messageController = StreamController<CoachingMessage>.broadcast();
    _conversationHistory.clear();
    
    // 初期メッセージ
    _sendCoachingMessage(
      'リアルタイムAIコーチングを開始します。自然に話してください。',
      CoachingType.system,
      priority: CoachingPriority.high,
    );
    
    // 定期的な分析タイマー
    _startAnalysisTimer();
    
    if (kDebugMode) {
      debugPrint('🎤 AI音声コーチング開始');
    }
  }

  /// 🎯 音声コーチング停止
  Future<void> stopCoaching() async {
    _isCoachingActive = false;
    _analysisTimer?.cancel();
    
    // 終了メッセージ
    _sendCoachingMessage(
      'お疲れ様でした！とても良い学級通信になりそうです。',
      CoachingType.completion,
      priority: CoachingPriority.medium,
    );
    
    await Future.delayed(Duration(seconds: 2));
    await _messageController?.close();
    _messageController = null;
    
    if (kDebugMode) {
      debugPrint('🎤 AI音声コーチング終了');
    }
  }

  /// 🎯 リアルタイム音声分析
  Future<void> analyzeRealTimeVoice(String transcriptChunk) async {
    if (!_isCoachingActive) return;
    
    _conversationHistory.add(transcriptChunk);
    
    // テキスト分析
    final analysis = await _analyzeContent(transcriptChunk);
    
    // 適切なコーチングメッセージを選択
    final coaching = _selectCoachingMessage(analysis);
    if (coaching != null) {
      _sendCoachingMessage(
        coaching.message,
        coaching.type,
        priority: coaching.priority,
      );
    }
  }

  /// 🎯 コンテンツ分析
  Future<ContentAnalysis> _analyzeContent(String text) async {
    final analysis = ContentAnalysis();
    
    // 基本的な分析
    analysis.wordCount = text.split(' ').length;
    analysis.sentenceCount = text.split('.').length;
    analysis.hasTimeReference = _hasTimeReference(text);
    analysis.hasSpecificDetails = _hasSpecificDetails(text);
    analysis.hasEmotionalContent = _hasEmotionalContent(text);
    analysis.speakingPace = _calculateSpeakingPace(text);
    analysis.contentType = _detectContentType(text);
    
    // 構造分析
    analysis.hasIntroduction = _hasIntroduction();
    analysis.hasBody = _hasBody();
    analysis.hasConclusion = _hasConclusion();
    
    return analysis;
  }

  /// 🎯 コーチングメッセージ選択
  CoachingMessage? _selectCoachingMessage(ContentAnalysis analysis) {
    // 会話の進行状況に応じて適切なメッセージを選択
    final historyLength = _conversationHistory.length;
    
    if (historyLength < 3) {
      // 開始段階
      return CoachingMessage(
        _getRandomMessage('encouragement'),
        CoachingType.encouragement,
        CoachingPriority.low,
      );
    } else if (historyLength < 8) {
      // 中間段階
      if (!analysis.hasSpecificDetails) {
        return CoachingMessage(
          _getRandomMessage('suggestion'),
          CoachingType.suggestion,
          CoachingPriority.medium,
        );
      } else if (!analysis.hasTimeReference) {
        return CoachingMessage(
          _getRandomMessage('clarification'),
          CoachingType.clarification,
          CoachingPriority.medium,
        );
      }
    } else if (historyLength > 15) {
      // 終了段階
      return CoachingMessage(
        _getRandomMessage('completion'),
        CoachingType.completion,
        CoachingPriority.high,
      );
    }
    
    // 構造的なアドバイス
    if (historyLength > 5 && !analysis.hasIntroduction) {
      return CoachingMessage(
        _getRandomMessage('structure'),
        CoachingType.structure,
        CoachingPriority.medium,
      );
    }
    
    return null;
  }

  /// 🎯 定期分析タイマー
  void _startAnalysisTimer() {
    _analysisTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (!_isCoachingActive) {
        timer.cancel();
        return;
      }
      
      _performPeriodicAnalysis();
    });
  }

  /// 🎯 定期分析実行
  void _performPeriodicAnalysis() {
    final totalWords = _conversationHistory.join(' ').split(' ').length;
    final duration = _conversationHistory.length * 10; // 秒
    
    if (totalWords < 50 && duration > 60) {
      _sendCoachingMessage(
        'もう少し詳しく話してみませんか？',
        CoachingType.suggestion,
        priority: CoachingPriority.medium,
      );
    } else if (totalWords > 300 && duration > 180) {
      _sendCoachingMessage(
        'とても詳しく話していただいています。そろそろまとめに入りませんか？',
        CoachingType.completion,
        priority: CoachingPriority.high,
      );
    }
  }

  /// 🎯 コーチングメッセージ送信
  void _sendCoachingMessage(
    String message,
    CoachingType type, {
    CoachingPriority priority = CoachingPriority.medium,
  }) {
    if (_messageController?.isClosed == false) {
      _messageController?.add(CoachingMessage(message, type, priority));
    }
  }

  /// 🎯 ランダムメッセージ取得
  String _getRandomMessage(String category) {
    final messages = _coachingMessages[category] ?? ['頑張ってください！'];
    return messages[(DateTime.now().millisecondsSinceEpoch) % messages.length];
  }

  /// 🎯 時間参照の検出
  bool _hasTimeReference(String text) {
    final timeKeywords = ['今日', '昨日', '先週', '今月', '月曜日', '火曜日', '水曜日', 
                         '木曜日', '金曜日', '土曜日', '日曜日', '午前', '午後'];
    return timeKeywords.any((keyword) => text.contains(keyword));
  }

  /// 🎯 具体的詳細の検出
  bool _hasSpecificDetails(String text) {
    return text.contains('写真') || 
           text.contains('様子') || 
           text.contains('活動') || 
           text.contains('子ども') ||
           text.contains('みんな');
  }

  /// 🎯 感情的内容の検出
  bool _hasEmotionalContent(String text) {
    final emotionalWords = ['楽しい', '嬉しい', '頑張', '素晴らしい', '良い', '感動'];
    return emotionalWords.any((word) => text.contains(word));
  }

  /// 🎯 話速度計算
  double _calculateSpeakingPace(String text) {
    // 簡易的な話速度計算（実際の実装では音声データから算出）
    return text.length / 10.0; // 文字数/10秒
  }

  /// 🎯 コンテンツタイプ検出
  ContentType _detectContentType(String text) {
    if (text.contains('行事') || text.contains('イベント')) {
      return ContentType.event;
    } else if (text.contains('授業') || text.contains('学習')) {
      return ContentType.lesson;
    } else if (text.contains('お知らせ') || text.contains('連絡')) {
      return ContentType.announcement;
    }
    return ContentType.general;
  }

  /// 🎯 導入部分の検出
  bool _hasIntroduction() {
    return _conversationHistory.any((text) => 
      text.contains('はじめに') || 
      text.contains('こんにちは') ||
      text.contains('いつもお世話になっております'));
  }

  /// 🎯 本文の検出
  bool _hasBody() {
    return _conversationHistory.length > 3;
  }

  /// 🎯 結論の検出
  bool _hasConclusion() {
    return _conversationHistory.any((text) => 
      text.contains('最後に') || 
      text.contains('ありがとう') ||
      text.contains('今後とも'));
  }

  /// 🎯 メッセージストリーム
  Stream<CoachingMessage>? get messageStream => _messageController?.stream;

  /// 🎯 コーチング状態
  bool get isActive => _isCoachingActive;

  /// 🎯 ユーザープロファイル更新
  void updateUserProfile(Map<String, dynamic> profile) {
    _userProfile = profile;
  }

  /// 🎯 学習データ保存
  Future<void> saveLearningData() async {
    // 実際の実装では永続化ストレージに保存
    if (kDebugMode) {
      debugPrint('🧠 学習データ保存: ${_conversationHistory.length}件');
    }
  }
}

/// コーチングメッセージクラス
class CoachingMessage {
  final String message;
  final CoachingType type;
  final CoachingPriority priority;
  final DateTime timestamp;

  CoachingMessage(
    this.message,
    this.type,
    this.priority,
  ) : timestamp = DateTime.now();
}

/// コーチングタイプ
enum CoachingType {
  system,
  encouragement,
  suggestion,
  structure,
  clarification,
  completion,
}

/// コーチング優先度
enum CoachingPriority {
  low,
  medium,
  high,
}

/// コンテンツ分析クラス
class ContentAnalysis {
  int wordCount = 0;
  int sentenceCount = 0;
  bool hasTimeReference = false;
  bool hasSpecificDetails = false;
  bool hasEmotionalContent = false;
  double speakingPace = 0.0;
  ContentType contentType = ContentType.general;
  bool hasIntroduction = false;
  bool hasBody = false;
  bool hasConclusion = false;
}

/// コンテンツタイプ
enum ContentType {
  general,
  event,
  lesson,
  announcement,
}

/// 音声コーチング用ウィジェット
class AIVoiceCoachingWidget extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onClose;

  const AIVoiceCoachingWidget({
    super.key,
    required this.isVisible,
    this.onClose,
  });

  @override
  State<AIVoiceCoachingWidget> createState() => _AIVoiceCoachingWidgetState();
}

class _AIVoiceCoachingWidgetState extends State<AIVoiceCoachingWidget>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final AIVoiceCoachingService _coachingService = AIVoiceCoachingService();
  CoachingMessage? _currentMessage;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // メッセージストリーム監視
    _coachingService.messageStream?.listen((message) {
      if (mounted) {
        setState(() {
          _currentMessage = message;
        });
        _showMessage();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showMessage() {
    _animationController.forward();
    
    // 3秒後に自動的に非表示
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || _currentMessage == null) {
      return SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getBackgroundColor(_currentMessage!.type),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _getIcon(_currentMessage!.type),
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _currentMessage!.message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (widget.onClose != null)
              IconButton(
                onPressed: widget.onClose,
                icon: Icon(Icons.close, color: Colors.white, size: 18),
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(CoachingType type) {
    switch (type) {
      case CoachingType.encouragement:
        return Colors.green[600]!;
      case CoachingType.suggestion:
        return Colors.blue[600]!;
      case CoachingType.structure:
        return Colors.orange[600]!;
      case CoachingType.clarification:
        return Colors.purple[600]!;
      case CoachingType.completion:
        return Colors.teal[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getIcon(CoachingType type) {
    switch (type) {
      case CoachingType.encouragement:
        return Icons.thumb_up;
      case CoachingType.suggestion:
        return Icons.lightbulb;
      case CoachingType.structure:
        return Icons.format_list_bulleted;
      case CoachingType.clarification:
        return Icons.help_outline;
      case CoachingType.completion:
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }
}