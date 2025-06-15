import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 🚀 Revolutionary Innovation 3: 自動季節感検出システム
/// 音声・テキストから季節・行事を自動検出し、適切なスタイル・色調を適用
class SeasonalDetectionService {
  static final SeasonalDetectionService _instance = SeasonalDetectionService._internal();
  factory SeasonalDetectionService() => _instance;
  SeasonalDetectionService._internal();

  // 季節検出データ
  final Map<Season, SeasonalData> _seasonalData = {
    Season.spring: SeasonalData(
      keywords: [
        '春', '桜', '入学式', '始業式', '新学期', '花見', '遠足', '新緑',
        '4月', '5月', '6月', 'さくら', '入学', '進級', '新入生',
        'こどもの日', '母の日', '運動会', '春の遠足', '田植え',
      ],
      colors: [
        '#FFB6C1', // ライトピンク
        '#98FB98', // ペールグリーン
        '#F0E68C', // カーキ
        '#FFC0CB', // ピンク
        '#90EE90', // ライトグリーン
      ],
      themes: ['桜と新緑', '新学期の始まり', '春の自然'],
      fonts: ['明るい', 'やわらか', '希望'],
    ),
    Season.summer: SeasonalData(
      keywords: [
        '夏', '海', 'プール', '夏休み', '花火', '祭り', '暑い', '夏祭り',
        '7月', '8月', '9月', '終業式', '水泳', '夏の思い出', 'キャンプ',
        '七夕', '海水浴', '虫取り', 'ひまわり', '蝉', 'すいか',
      ],
      colors: [
        '#87CEEB', // スカイブルー
        '#FFD700', // ゴールド
        '#FF6347', // トマト色
        '#40E0D0', // ターコイズ
        '#FFFF00', // イエロー
      ],
      themes: ['夏の太陽', '海と空', '元気な夏'],
      fonts: ['元気', 'アクティブ', '明るい'],
    ),
    Season.autumn: SeasonalData(
      keywords: [
        '秋', '紅葉', '運動会', '文化祭', '学習発表会', '収穫', '芋掘り',
        '10月', '11月', '12月', 'もみじ', '読書', '秋の遠足', '音楽会',
        'ハロウィン', '七五三', '勤労感謝', '落ち葉', 'どんぐり',
      ],
      colors: [
        '#CD853F', // ペルー色
        '#D2691E', // チョコレート
        '#FF8C00', // ダークオレンジ
        '#B22222', // ファイアブリック
        '#8B4513', // サドルブラウン
      ],
      themes: ['秋の実り', '紅葉の美しさ', '学習の秋'],
      fonts: ['落ち着いた', '温かい', '知的'],
    ),
    Season.winter: SeasonalData(
      keywords: [
        '冬', '雪', 'クリスマス', '年末', '年始', '正月', '節分', '寒い',
        '1月', '2月', '3月', '卒業式', '雪だるま', 'スキー', '餅つき',
        'イルミネーション', '大掃除', 'お正月', '豆まき', '雛祭り',
      ],
      colors: [
        '#B0E0E6', // パウダーブルー
        '#FFFFFF', // ホワイト
        '#C0C0C0', // シルバー
        '#4682B4', // スチールブルー
        '#E6E6FA', // ラベンダー
      ],
      themes: ['雪の結晶', '静寂な冬', '温かい心'],
      fonts: ['清楚', '上品', '静か'],
    ),
  };

  // 学校行事データ
  final Map<String, SchoolEvent> _schoolEvents = {
    '入学式': SchoolEvent('入学式', Season.spring, EventType.ceremony, 4),
    '始業式': SchoolEvent('始業式', Season.spring, EventType.ceremony, 4),
    '運動会': SchoolEvent('運動会', Season.autumn, EventType.sports, 10),
    '文化祭': SchoolEvent('文化祭', Season.autumn, EventType.cultural, 11),
    '卒業式': SchoolEvent('卒業式', Season.winter, EventType.ceremony, 3),
    '遠足': SchoolEvent('遠足', Season.spring, EventType.excursion, 5),
    '夏祭り': SchoolEvent('夏祭り', Season.summer, EventType.festival, 8),
    '学習発表会': SchoolEvent('学習発表会', Season.autumn, EventType.presentation, 11),
    'クリスマス会': SchoolEvent('クリスマス会', Season.winter, EventType.festival, 12),
  };

  // 地域別学校行事カレンダー（精密拡張版）
  final Map<String, List<RegionalEvent>> _regionalEvents = {
    '関東': [
      RegionalEvent('桜祭り', 4, Season.spring),
      RegionalEvent('こどもの日集会', 5, Season.spring),
      RegionalEvent('夏休みプール開放', 7, Season.summer),
      RegionalEvent('七夕まつり', 7, Season.summer),
      RegionalEvent('秋の音楽会', 10, Season.autumn),
      RegionalEvent('紅葉狩り遠足', 11, Season.autumn),
      RegionalEvent('雪遊び大会', 1, Season.winter),
      RegionalEvent('節分豆まき', 2, Season.winter),
    ],
    '関西': [
      RegionalEvent('花見遠足', 4, Season.spring),
      RegionalEvent('母の日参観', 5, Season.spring),
      RegionalEvent('夏祭り', 8, Season.summer),
      RegionalEvent('盆踊り大会', 8, Season.summer),
      RegionalEvent('もみじ狩り', 11, Season.autumn),
      RegionalEvent('秋祭り', 10, Season.autumn),
      RegionalEvent('餅つき大会', 12, Season.winter),
      RegionalEvent('節分行事', 2, Season.winter),
    ],
    '東北': [
      RegionalEvent('雪解け祭り', 4, Season.spring),
      RegionalEvent('田植え体験', 5, Season.spring),
      RegionalEvent('ねぶた見学', 8, Season.summer),
      RegionalEvent('収穫祭', 10, Season.autumn),
      RegionalEvent('かまくら作り', 1, Season.winter),
      RegionalEvent('雪中運動会', 2, Season.winter),
    ],
    '九州': [
      RegionalEvent('桜前線祭り', 3, Season.spring),
      RegionalEvent('茶摘み体験', 5, Season.spring),
      RegionalEvent('七夕竹飾り', 7, Season.summer),
      RegionalEvent('夏越祭', 6, Season.summer),
      RegionalEvent('彼岸花見学', 9, Season.autumn),
      RegionalEvent('みかん狩り', 11, Season.autumn),
      RegionalEvent('クリスマス市', 12, Season.winter),
      RegionalEvent('初日の出登山', 1, Season.winter),
    ],
    '北海道': [
      RegionalEvent('雪解け運動会', 5, Season.spring),
      RegionalEvent('ライラック祭り', 5, Season.spring),
      RegionalEvent('ラベンダー見学', 7, Season.summer),
      RegionalEvent('とうもろこし収穫', 8, Season.summer),
      RegionalEvent('紅葉ハイキング', 10, Season.autumn),
      RegionalEvent('芋掘り体験', 9, Season.autumn),
      RegionalEvent('雪まつり', 2, Season.winter),
      RegionalEvent('スキー教室', 1, Season.winter),
    ],
    '沖縄': [
      RegionalEvent('ひまわり祭り', 1, Season.winter), // 沖縄は冬が温暖
      RegionalEvent('桜まつり', 1, Season.winter), // 沖縄の桜は1-2月
      RegionalEvent('海開き', 3, Season.spring),
      RegionalEvent('エイサー祭り', 8, Season.summer),
      RegionalEvent('台風体験学習', 9, Season.autumn),
      RegionalEvent('シーサー作り', 11, Season.autumn),
    ],
  };

  /// 🎯 地域を自動検出
  String detectRegionFromText(String text) {
    final regionKeywords = {
      '北海道': ['北海道', 'ライラック', 'ラベンダー', '雪まつり', 'スキー', 'とうもろこし'],
      '東北': ['東北', 'ねぶた', 'かまくら', '雪解け', '田植え', '収穫祭'],
      '関東': ['関東', '東京', '神奈川', '埼玉', '千葉', '茨城', '栃木', '群馬'],
      '関西': ['関西', '大阪', '京都', '兵庫', '奈良', '和歌山', '滋賀', 'もみじ狩り'],
      '九州': ['九州', '福岡', '佐賀', '長崎', '熊本', '大分', '宮崎', '鹿児島', 'みかん', '彼岸花'],
      '沖縄': ['沖縄', 'エイサー', 'シーサー', '海開き', 'ひまわり', '台風'],
    };
    
    for (final entry in regionKeywords.entries) {
      final region = entry.key;
      final keywords = entry.value;
      
      for (final keyword in keywords) {
        if (text.contains(keyword)) {
          return region;
        }
      }
    }
    
    // デフォルトは関東
    return '関東';
  }

  /// 🎯 精密地域カレンダー連携検出
  Future<RegionalSeasonalResult> detectRegionalSeasonal(String text) async {
    final detectedRegion = detectRegionFromText(text);
    final currentMonth = DateTime.now().month;
    
    // 基本季節検出
    final baseResult = await detectSeasonFromText(text);
    
    // 地域イベント検出
    final regionalEvents = _regionalEvents[detectedRegion] ?? [];
    final currentMonthEvents = regionalEvents.where((event) => event.month == currentMonth).toList();
    final detectedRegionalEvents = regionalEvents.where((event) => text.contains(event.name)).toList();
    
    // 地域特有の季節キーワード
    final regionalKeywords = _getRegionalKeywords(detectedRegion, baseResult.primarySeason);
    
    return RegionalSeasonalResult(
      region: detectedRegion,
      baseSeasonalResult: baseResult,
      currentMonthEvents: currentMonthEvents,
      detectedRegionalEvents: detectedRegionalEvents,
      regionalKeywords: regionalKeywords,
      recommendedColors: _getRegionalColors(detectedRegion),
      confidence: baseResult.confidence * (detectedRegionalEvents.isNotEmpty ? 1.2 : 1.0),
    );
  }

  /// 🎯 地域特有キーワード取得
  List<String> _getRegionalKeywords(String region, Season season) {
    final regionalSeasonKeywords = {
      '北海道': {
        Season.spring: ['雪解け', 'ライラック', '短い春'],
        Season.summer: ['ラベンダー', '涼しい夏', '白夜'],
        Season.autumn: ['早い紅葉', 'じゃがいも', '初雪'],
        Season.winter: ['雪景色', 'スキー', '流氷'],
      },
      '沖縄': {
        Season.spring: ['海開き', '桜前線終点', '梅雨入り'],
        Season.summer: ['台風', '猛暑', 'マリンスポーツ'],
        Season.autumn: ['台風シーズン', '過ごしやすい'],
        Season.winter: ['温暖', '桜咲く', 'ひまわり'],
      },
      '東北': {
        Season.spring: ['雪解け', '遅い春', '山菜'],
        Season.summer: ['ねぶた', '短い夏', '涼しい'],
        Season.autumn: ['早い紅葉', '収穫', '稲刈り'],
        Season.winter: ['豪雪', 'かまくら', '雪国'],
      },
      '九州': {
        Season.spring: ['桜前線スタート', '温暖', '菜の花'],
        Season.summer: ['梅雨明け', '猛暑', '台風'],
        Season.autumn: ['彼岸花', 'みかん', '温暖'],
        Season.winter: ['温暖な冬', '椿', '梅'],
      },
    };
    
    return regionalSeasonKeywords[region]?[season] ?? [];
  }

  /// 🎯 地域特有カラーパレット取得
  List<String> _getRegionalColors(String region) {
    final regionalColors = {
      '北海道': ['#87CEEB', '#E6E6FA', '#B0E0E6', '#F0F8FF'], // 空色・ラベンダー系
      '沖縄': ['#00CED1', '#FFD700', '#FF6347', '#98FB98'], // 海・太陽系
      '東北': ['#228B22', '#8B4513', '#A0522D', '#2F4F4F'], // 自然・大地系
      '九州': ['#FF69B4', '#FFA500', '#32CD32', '#FF1493'], // 桜・温暖系
      '関東': ['#4169E1', '#FFB6C1', '#98FB98', '#DDA0DD'], // 都市・桜系
      '関西': ['#DC143C', '#FFD700', '#9370DB', '#20B2AA'], // 伝統・文化系
    };
    
    return regionalColors[region] ?? regionalColors['関東']!;
  }

  /// 🎯 テキストから季節を検出
  Future<SeasonalDetectionResult> detectSeasonFromText(String text) async {
    final currentMonth = DateTime.now().month;
    final detectedSeasons = <Season, double>{};
    
    // キーワードベースの検出
    for (final entry in _seasonalData.entries) {
      final season = entry.key;
      final data = entry.value;
      
      double score = 0.0;
      for (final keyword in data.keywords) {
        if (text.contains(keyword)) {
          score += 1.0;
          // 複数回出現する場合はスコア加算
          final occurrences = _countOccurrences(text, keyword);
          score += (occurrences - 1) * 0.5;
        }
      }
      
      // 現在の月に基づくボーナススコア
      score += _getMonthlyBonus(season, currentMonth);
      
      if (score > 0) {
        detectedSeasons[season] = score;
      }
    }
    
    // 学校行事の検出
    final detectedEvents = <SchoolEvent>[];
    for (final entry in _schoolEvents.entries) {
      if (text.contains(entry.key)) {
        detectedEvents.add(entry.value);
      }
    }
    
    // 最も高いスコアの季節を選択
    Season? primarySeason;
    double maxScore = 0.0;
    
    for (final entry in detectedSeasons.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        primarySeason = entry.key;
      }
    }
    
    // デフォルトは現在の季節
    primarySeason ??= _getCurrentSeason();
    
    return SeasonalDetectionResult(
      primarySeason: primarySeason,
      confidence: maxScore / 10.0, // 0-1に正規化
      detectedEvents: detectedEvents,
      suggestedColors: _seasonalData[primarySeason]?.colors ?? [],
      suggestedThemes: _seasonalData[primarySeason]?.themes ?? [],
      seasonalKeywords: _getDetectedKeywords(text, primarySeason),
    );
  }

  /// 🎯 現在の季節を取得
  Season _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.autumn;
    return Season.winter;
  }

  /// 🎯 月別ボーナススコア
  double _getMonthlyBonus(Season season, int month) {
    switch (season) {
      case Season.spring:
        return (month >= 3 && month <= 5) ? 2.0 : 0.0;
      case Season.summer:
        return (month >= 6 && month <= 8) ? 2.0 : 0.0;
      case Season.autumn:
        return (month >= 9 && month <= 11) ? 2.0 : 0.0;
      case Season.winter:
        return (month == 12 || month <= 2) ? 2.0 : 0.0;
    }
  }

  /// 🎯 キーワード出現回数をカウント
  int _countOccurrences(String text, String keyword) {
    return keyword.allMatches(text).length;
  }

  /// 🎯 検出されたキーワードを取得
  List<String> _getDetectedKeywords(String text, Season season) {
    final keywords = _seasonalData[season]?.keywords ?? [];
    return keywords.where((keyword) => text.contains(keyword)).toList();
  }

  /// 🎯 季節に応じたテンプレートを生成
  Future<SeasonalTemplate> generateSeasonalTemplate(
    SeasonalDetectionResult detection,
  ) async {
    final season = detection.primarySeason;
    final data = _seasonalData[season]!;
    
    return SeasonalTemplate(
      primaryColor: data.colors.first,
      accentColor: data.colors.length > 1 ? data.colors[1] : data.colors.first,
      backgroundPattern: _generateBackgroundPattern(season),
      fontStyle: _generateFontStyle(season),
      headerStyle: _generateHeaderStyle(season),
      borderStyle: _generateBorderStyle(season),
      decorativeElements: _generateDecorativeElements(season, detection.detectedEvents),
    );
  }

  /// 🎯 背景パターン生成
  String _generateBackgroundPattern(Season season) {
    switch (season) {
      case Season.spring:
        return 'url("data:image/svg+xml,<svg xmlns=\'http://www.w3.org/2000/svg\' width=\'40\' height=\'40\' viewBox=\'0 0 40 40\'><circle cx=\'20\' cy=\'20\' r=\'3\' fill=\'%23FFB6C1\' opacity=\'0.3\'/></svg>")';
      case Season.summer:
        return 'linear-gradient(45deg, #87CEEB 25%, transparent 25%), linear-gradient(-45deg, #87CEEB 25%, transparent 25%)';
      case Season.autumn:
        return 'url("data:image/svg+xml,<svg xmlns=\'http://www.w3.org/2000/svg\' width=\'20\' height=\'20\' viewBox=\'0 0 20 20\'><path d=\'M10 2L12 8L18 10L12 12L10 18L8 12L2 10L8 8Z\' fill=\'%23CD853F\' opacity=\'0.2\'/></svg>")';
      case Season.winter:
        return 'url("data:image/svg+xml,<svg xmlns=\'http://www.w3.org/2000/svg\' width=\'30\' height=\'30\' viewBox=\'0 0 30 30\'><path d=\'M15 5L16 14L25 15L16 16L15 25L14 16L5 15L14 14Z\' fill=\'%23B0E0E6\' opacity=\'0.3\'/></svg>")';
    }
  }

  /// 🎯 フォントスタイル生成
  Map<String, dynamic> _generateFontStyle(Season season) {
    final data = _seasonalData[season]!;
    
    return {
      'fontFamily': 'Noto Sans JP, sans-serif',
      'fontWeight': season == Season.autumn ? '500' : '400',
      'letterSpacing': season == Season.winter ? '0.05em' : '0.02em',
      'lineHeight': '1.6',
      'textShadow': season == Season.summer ? '1px 1px 2px rgba(0,0,0,0.1)' : 'none',
    };
  }

  /// 🎯 ヘッダースタイル生成
  Map<String, dynamic> _generateHeaderStyle(Season season) {
    final data = _seasonalData[season]!;
    
    return {
      'backgroundColor': data.colors.first,
      'color': _getContrastColor(data.colors.first),
      'padding': '16px',
      'borderRadius': season == Season.spring ? '12px' : '8px',
      'boxShadow': '0 2px 8px rgba(0,0,0,0.1)',
      'backgroundImage': _generateBackgroundPattern(season),
    };
  }

  /// 🎯 ボーダースタイル生成
  Map<String, dynamic> _generateBorderStyle(Season season) {
    final data = _seasonalData[season]!;
    
    return {
      'borderColor': data.colors.first,
      'borderWidth': '2px',
      'borderStyle': season == Season.winter ? 'solid' : 'dashed',
      'borderRadius': '8px',
    };
  }

  /// 🎯 装飾要素生成
  List<DecorativeElement> _generateDecorativeElements(
    Season season,
    List<SchoolEvent> events,
  ) {
    final elements = <DecorativeElement>[];
    
    switch (season) {
      case Season.spring:
        elements.add(DecorativeElement('🌸', 'top-right'));
        elements.add(DecorativeElement('🌱', 'bottom-left'));
        break;
      case Season.summer:
        elements.add(DecorativeElement('☀️', 'top-left'));
        elements.add(DecorativeElement('🏖️', 'bottom-right'));
        break;
      case Season.autumn:
        elements.add(DecorativeElement('🍂', 'top-left'));
        elements.add(DecorativeElement('🍄', 'bottom-right'));
        break;
      case Season.winter:
        elements.add(DecorativeElement('❄️', 'top-right'));
        elements.add(DecorativeElement('⛄', 'bottom-left'));
        break;
    }
    
    // イベント固有の装飾
    for (final event in events) {
      switch (event.type) {
        case EventType.ceremony:
          elements.add(DecorativeElement('🎓', 'header'));
          break;
        case EventType.sports:
          elements.add(DecorativeElement('🏃', 'header'));
          break;
        case EventType.cultural:
          elements.add(DecorativeElement('🎭', 'header'));
          break;
        case EventType.festival:
          elements.add(DecorativeElement('🎉', 'header'));
          break;
        default:
          break;
      }
    }
    
    return elements;
  }

  /// 🎯 コントラストカラー取得
  String _getContrastColor(String hexColor) {
    // 簡易的な明度計算でコントラストカラーを決定
    final color = hexColor.replaceAll('#', '');
    final r = int.parse(color.substring(0, 2), radix: 16);
    final g = int.parse(color.substring(2, 4), radix: 16);
    final b = int.parse(color.substring(4, 6), radix: 16);
    
    final brightness = (r * 299 + g * 587 + b * 114) / 1000;
    return brightness > 128 ? '#000000' : '#FFFFFF';
  }

  /// 🎯 地域別カレンダー連携
  Future<List<RegionalEvent>> getRegionalEvents(String region) async {
    return _regionalEvents[region] ?? [];
  }

  /// 🎯 季節感検出結果をCSS生成
  String generateSeasonalCSS(SeasonalTemplate template) {
    return '''
      .seasonal-newsletter {
        background-color: ${template.primaryColor};
        background-image: ${template.backgroundPattern};
        border: ${template.borderStyle['borderWidth']} ${template.borderStyle['borderStyle']} ${template.borderStyle['borderColor']};
        border-radius: ${template.borderStyle['borderRadius']};
        font-family: ${template.fontStyle['fontFamily']};
        font-weight: ${template.fontStyle['fontWeight']};
        letter-spacing: ${template.fontStyle['letterSpacing']};
        line-height: ${template.fontStyle['lineHeight']};
      }
      
      .seasonal-header {
        background-color: ${template.headerStyle['backgroundColor']};
        color: ${template.headerStyle['color']};
        padding: ${template.headerStyle['padding']};
        border-radius: ${template.headerStyle['borderRadius']};
        box-shadow: ${template.headerStyle['boxShadow']};
        background-image: ${template.headerStyle['backgroundImage']};
      }
      
      .seasonal-accent {
        color: ${template.accentColor};
        border-left: 4px solid ${template.accentColor};
        padding-left: 12px;
      }
    ''';
  }
}

/// 季節列挙
enum Season { spring, summer, autumn, winter }

/// イベントタイプ
enum EventType { ceremony, sports, cultural, festival, excursion, presentation }

/// 季節データクラス
class SeasonalData {
  final List<String> keywords;
  final List<String> colors;
  final List<String> themes;
  final List<String> fonts;

  SeasonalData({
    required this.keywords,
    required this.colors,
    required this.themes,
    required this.fonts,
  });
}

/// 学校行事クラス
class SchoolEvent {
  final String name;
  final Season season;
  final EventType type;
  final int month;

  SchoolEvent(this.name, this.season, this.type, this.month);
}

/// 地域イベントクラス
class RegionalEvent {
  final String name;
  final int month;
  final Season season;

  RegionalEvent(this.name, this.month, this.season);
}

/// 季節検出結果クラス
class SeasonalDetectionResult {
  final Season primarySeason;
  final double confidence;
  final List<SchoolEvent> detectedEvents;
  final List<String> suggestedColors;
  final List<String> suggestedThemes;
  final List<String> seasonalKeywords;

  SeasonalDetectionResult({
    required this.primarySeason,
    required this.confidence,
    required this.detectedEvents,
    required this.suggestedColors,
    required this.suggestedThemes,
    required this.seasonalKeywords,
  });
}

/// 季節テンプレートクラス
class SeasonalTemplate {
  final String primaryColor;
  final String accentColor;
  final String backgroundPattern;
  final Map<String, dynamic> fontStyle;
  final Map<String, dynamic> headerStyle;
  final Map<String, dynamic> borderStyle;
  final List<DecorativeElement> decorativeElements;

  SeasonalTemplate({
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundPattern,
    required this.fontStyle,
    required this.headerStyle,
    required this.borderStyle,
    required this.decorativeElements,
  });
}

/// 🎯 地域季節感統合結果クラス
class RegionalSeasonalResult {
  final String region;
  final SeasonalDetectionResult baseSeasonalResult;
  final List<RegionalEvent> currentMonthEvents;
  final List<RegionalEvent> detectedRegionalEvents;
  final List<String> regionalKeywords;
  final List<String> recommendedColors;
  final double confidence;

  RegionalSeasonalResult({
    required this.region,
    required this.baseSeasonalResult,
    required this.currentMonthEvents,
    required this.detectedRegionalEvents,
    required this.regionalKeywords,
    required this.recommendedColors,
    required this.confidence,
  });
}

/// 装飾要素クラス
class DecorativeElement {
  final String emoji;
  final String position;

  DecorativeElement(this.emoji, this.position);
}

/// 季節感検出ウィジェット
class SeasonalDetectionWidget extends StatefulWidget {
  final String inputText;
  final Function(SeasonalTemplate) onTemplateGenerated;

  const SeasonalDetectionWidget({
    Key? key,
    required this.inputText,
    required this.onTemplateGenerated,
  }) : super(key: key);

  @override
  State<SeasonalDetectionWidget> createState() => _SeasonalDetectionWidgetState();
}

class _SeasonalDetectionWidgetState extends State<SeasonalDetectionWidget> {
  final SeasonalDetectionService _detectionService = SeasonalDetectionService();
  SeasonalDetectionResult? _detectionResult;
  SeasonalTemplate? _template;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _analyzeText();
  }

  @override
  void didUpdateWidget(SeasonalDetectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inputText != widget.inputText) {
      _analyzeText();
    }
  }

  Future<void> _analyzeText() async {
    if (widget.inputText.isEmpty) return;
    
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _detectionService.detectSeasonFromText(widget.inputText);
      final template = await _detectionService.generateSeasonalTemplate(result);
      
      setState(() {
        _detectionResult = result;
        _template = template;
        _isAnalyzing = false;
      });
      
      widget.onTemplateGenerated(template);
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      
      if (kDebugMode) {
        debugPrint('季節感検出エラー: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              '季節感を自動検出中...',
              style: TextStyle(color: Colors.blue[800]),
            ),
          ],
        ),
      );
    }

    if (_detectionResult == null) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.green[600]),
              SizedBox(width: 8),
              Text(
                '季節感自動検出結果',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '検出された季節: ${_getSeasonName(_detectionResult!.primarySeason)}',
            style: TextStyle(color: Colors.green[700]),
          ),
          if (_detectionResult!.detectedEvents.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              '学校行事: ${_detectionResult!.detectedEvents.map((e) => e.name).join(', ')}',
              style: TextStyle(color: Colors.green[700]),
            ),
          ],
          if (_detectionResult!.seasonalKeywords.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              'キーワード: ${_detectionResult!.seasonalKeywords.join(', ')}',
              style: TextStyle(color: Colors.green[700], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _getSeasonName(Season season) {
    switch (season) {
      case Season.spring:
        return '春 🌸';
      case Season.summer:
        return '夏 ☀️';
      case Season.autumn:
        return '秋 🍂';
      case Season.winter:
        return '冬 ❄️';
    }
  }
}