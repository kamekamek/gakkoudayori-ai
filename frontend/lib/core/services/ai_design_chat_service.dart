import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../widgets/ai_design_chat_widget.dart';
import '../widgets/adk_agent_dashboard.dart';

/// AIデザインチャットサービス
/// 
/// バックエンドのAIエンジンと連携して、ユーザーの修正要求を
/// 自然言語解析し、HTMLデザインをリアルタイムで修正する
class AIDesignChatService {
  static String get _baseUrl => AppConfig.apiBaseUrl;
  
  /// デザイン修正チャット
  Future<DesignChatResponse> processDesignChat({
    required String userMessage,
    required String currentHtml,
    required String conversationId,
    required NewsletterStyle style,
    List<DesignModificationRecord> modificationHistory = const [],
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🤖 AIデザインチャット開始 - メッセージ: $userMessage');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/design-chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_message': userMessage,
          'current_html': currentHtml,
          'conversation_id': conversationId,
          'style': style == NewsletterStyle.classic ? 'classic' : 'modern',
          'modification_history': modificationHistory.map((m) => m.toJson()).toList(),
        }),
      );

      if (kDebugMode) {
        debugPrint('🤖 AIデザインチャット応答 - ステータス: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final result = DesignChatResponse.fromJson(data['data']);
          if (kDebugMode) {
            debugPrint('✅ AIデザインチャット成功 - 修正タイプ: ${result.modificationType}');
          }
          return result;
        } else {
          throw Exception(data['error'] ?? 'Unknown design chat error');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('API Error: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AIデザインチャットエラー: $e');
      }
      throw Exception('AIデザインチャットに失敗しました: $e');
    }
  }
  
  /// 意図分析（ローカル処理）
  DesignIntent analyzeDesignIntent(String userMessage) {
    final message = userMessage.toLowerCase();
    
    // 色調修正の意図
    if (_containsAny(message, ['色', '明るい', '暗い', '鮮やか', '薄い', 'カラー', '青', '赤', '緑', '黄色', 'ピンク'])) {
      final params = <String, dynamic>{};
      
      if (_containsAny(message, ['明るい', '明るく', '鮮やか'])) {
        params['brightness'] = 'brighter';
      } else if (_containsAny(message, ['暗い', '暗く', '落ち着いた'])) {
        params['brightness'] = 'darker';
      }
      
      if (_containsAny(message, ['青', 'ブルー'])) {
        params['color_hint'] = 'blue';
      } else if (_containsAny(message, ['赤', 'レッド'])) {
        params['color_hint'] = 'red';
      } else if (_containsAny(message, ['緑', 'グリーン'])) {
        params['color_hint'] = 'green';
      }
      
      return DesignIntent(
        type: DesignModificationType.color,
        confidence: 0.9,
        parameters: params,
        description: '色調を調整します',
      );
    }
    
    // レイアウト修正の意図
    if (_containsAny(message, ['レイアウト', '配置', '列', '行', '中央', '左', '右', 'センター'])) {
      final params = <String, dynamic>{};
      
      if (_containsAny(message, ['2列', '二列', 'ツーカラム'])) {
        params['columns'] = 2;
      } else if (_containsAny(message, ['1列', '一列', 'シングル'])) {
        params['columns'] = 1;
      }
      
      if (_containsAny(message, ['中央', 'センター', '真ん中'])) {
        params['alignment'] = 'center';
      } else if (_containsAny(message, ['左', '左側'])) {
        params['alignment'] = 'left';
      } else if (_containsAny(message, ['右', '右側'])) {
        params['alignment'] = 'right';
      }
      
      return DesignIntent(
        type: DesignModificationType.layout,
        confidence: 0.85,
        parameters: params,
        description: 'レイアウトを調整します',
      );
    }
    
    // フォント修正の意図
    if (_containsAny(message, ['文字', 'フォント', '大きく', '小さく', '太く', '細く', 'サイズ'])) {
      final params = <String, dynamic>{};
      
      if (_containsAny(message, ['大きく', '大きい', '拡大'])) {
        params['size_change'] = 'larger';
      } else if (_containsAny(message, ['小さく', '小さい', '縮小'])) {
        params['size_change'] = 'smaller';
      }
      
      if (_containsAny(message, ['太く', '太い', 'ボールド'])) {
        params['weight'] = 'bold';
      } else if (_containsAny(message, ['細く', '細い', 'ライト'])) {
        params['weight'] = 'light';
      }
      
      return DesignIntent(
        type: DesignModificationType.font,
        confidence: 0.8,
        parameters: params,
        description: 'フォントを調整します',
      );
    }
    
    // 画像・メディア修正の意図
    if (_containsAny(message, ['画像', '写真', 'イメージ', '図', '絵'])) {
      final params = <String, dynamic>{};
      
      if (_containsAny(message, ['大きく', '大きい', '拡大'])) {
        params['size_change'] = 'larger';
      } else if (_containsAny(message, ['小さく', '小さい', '縮小'])) {
        params['size_change'] = 'smaller';
      }
      
      if (_containsAny(message, ['追加', '挿入', '入れる'])) {
        params['action'] = 'add';
      } else if (_containsAny(message, ['削除', '消す', '除く'])) {
        params['action'] = 'remove';
      }
      
      return DesignIntent(
        type: DesignModificationType.layout, // 画像は主にレイアウト調整
        confidence: 0.75,
        parameters: params,
        description: '画像を調整します',
      );
    }
    
    // 内容修正の意図
    if (_containsAny(message, ['内容', '文章', 'テキスト', '詳しく', '短く', '追加', '削除'])) {
      final params = <String, dynamic>{};
      
      if (_containsAny(message, ['詳しく', '詳細', '拡張', '長く'])) {
        params['content_change'] = 'expand';
      } else if (_containsAny(message, ['短く', '簡潔', '要約', '縮める'])) {
        params['content_change'] = 'summarize';
      }
      
      return DesignIntent(
        type: DesignModificationType.content,
        confidence: 0.7,
        parameters: params,
        description: '内容を調整します',
      );
    }
    
    // 一般的な改善要求
    if (_containsAny(message, ['改善', '良く', 'きれい', '美しく', 'おしゃれ'])) {
      return DesignIntent(
        type: DesignModificationType.layout,
        confidence: 0.6,
        parameters: {'action': 'improve'},
        description: '全体的な改善を行います',
      );
    }
    
    // 意図が不明な場合
    return DesignIntent(
      type: DesignModificationType.layout,
      confidence: 0.3,
      parameters: {'original_message': userMessage},
      description: 'ご要望に応じて調整を試みます',
    );
  }
  
  /// 複数の単語のいずれかが含まれているかチェック
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// クイック修正の提案生成
  List<QuickModificationSuggestion> generateQuickSuggestions(
    String currentHtml,
    NewsletterStyle style,
  ) {
    final suggestions = <QuickModificationSuggestion>[];
    
    // スタイル別の基本提案
    if (style == NewsletterStyle.classic) {
      suggestions.addAll([
        QuickModificationSuggestion(
          id: 'classic_bright',
          label: '明るく',
          description: '色調を明るく調整',
          icon: '🌟',
          modificationType: DesignModificationType.color,
          command: '色を明るくして',
        ),
        QuickModificationSuggestion(
          id: 'classic_font',
          label: '読みやすく',
          description: 'フォントサイズを調整',
          icon: '📖',
          modificationType: DesignModificationType.font,
          command: '文字を読みやすくして',
        ),
      ]);
    } else {
      suggestions.addAll([
        QuickModificationSuggestion(
          id: 'modern_vivid',
          label: '鮮やかに',
          description: '色をより鮮やかに',
          icon: '🎨',
          modificationType: DesignModificationType.color,
          command: '色を鮮やかにして',
        ),
        QuickModificationSuggestion(
          id: 'modern_layout',
          label: 'モダンに',
          description: 'レイアウトをモダンに',
          icon: '✨',
          modificationType: DesignModificationType.layout,
          command: 'レイアウトをモダンにして',
        ),
      ]);
    }
    
    // 共通の提案
    suggestions.addAll([
      QuickModificationSuggestion(
        id: 'image_larger',
        label: '画像拡大',
        description: '写真を大きく表示',
        icon: '📸',
        modificationType: DesignModificationType.layout,
        command: '写真を大きくして',
      ),
      QuickModificationSuggestion(
        id: 'center_align',
        label: '中央揃え',
        description: '見出しを中央に配置',
        icon: '🎯',
        modificationType: DesignModificationType.layout,
        command: '見出しを中央揃えにして',
      ),
    ]);
    
    return suggestions;
  }
}

/// デザインチャットレスポンス
class DesignChatResponse {
  final String aiMessage;
  final String modifiedHtml;
  final DesignModificationType? modificationType;
  final bool canUndo;
  final double confidence;
  final Map<String, dynamic> metadata;

  DesignChatResponse({
    required this.aiMessage,
    required this.modifiedHtml,
    this.modificationType,
    this.canUndo = true,
    this.confidence = 0.0,
    this.metadata = const {},
  });

  factory DesignChatResponse.fromJson(Map<String, dynamic> json) {
    return DesignChatResponse(
      aiMessage: json['ai_message'] ?? '',
      modifiedHtml: json['modified_html'] ?? '',
      modificationType: json['modification_type'] != null
          ? _parseModificationType(json['modification_type'])
          : null,
      canUndo: json['can_undo'] ?? true,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      metadata: json['metadata'] ?? {},
    );
  }

  static DesignModificationType? _parseModificationType(String type) {
    switch (type.toLowerCase()) {
      case 'color':
        return DesignModificationType.color;
      case 'layout':
        return DesignModificationType.layout;
      case 'font':
        return DesignModificationType.font;
      case 'content':
        return DesignModificationType.content;
      default:
        return null;
    }
  }
}

/// デザイン意図解析結果
class DesignIntent {
  final DesignModificationType type;
  final double confidence;
  final Map<String, dynamic> parameters;
  final String description;

  DesignIntent({
    required this.type,
    required this.confidence,
    required this.parameters,
    required this.description,
  });
}

/// クイック修正提案
class QuickModificationSuggestion {
  final String id;
  final String label;
  final String description;
  final String icon;
  final DesignModificationType modificationType;
  final String command;

  QuickModificationSuggestion({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.modificationType,
    required this.command,
  });
}

/// デザイン修正記録
class DesignModificationRecord {
  final String id;
  final String userMessage;
  final String previousHtml;
  final String modifiedHtml;
  final DesignModificationType modificationType;
  final DateTime timestamp;
  final double confidence;

  DesignModificationRecord({
    required this.id,
    required this.userMessage,
    required this.previousHtml,
    required this.modifiedHtml,
    required this.modificationType,
    required this.timestamp,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_message': userMessage,
      'previous_html': previousHtml,
      'modified_html': modifiedHtml,
      'modification_type': modificationType.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
    };
  }

  factory DesignModificationRecord.fromJson(Map<String, dynamic> json) {
    return DesignModificationRecord(
      id: json['id'],
      userMessage: json['user_message'],
      previousHtml: json['previous_html'],
      modifiedHtml: json['modified_html'],
      modificationType: DesignChatResponse._parseModificationType(
          json['modification_type']) ?? DesignModificationType.layout,
      timestamp: DateTime.parse(json['timestamp']),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}