import 'package:flutter/material.dart';

/// DateTime拡張
extension DateTimeExtensions on DateTime {
  /// 日本語形式の日付文字列を取得
  String toJapaneseDate() {
    return '$year年$month月$day日';
  }
  
  /// 時間を含む日本語形式の日付文字列を取得
  String toJapaneseDateTime() {
    return '$year年$month月$day日 $hour時$minute分';
  }
  
  /// 相対時間表示（例：3分前、1時間前）
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }
}

/// String拡張
extension StringExtensions on String {
  /// 空文字やnullの場合にデフォルト値を返す
  String orDefault(String defaultValue) {
    return isEmpty ? defaultValue : this;
  }
  
  /// HTMLタグを除去
  String stripHtmlTags() {
    return replaceAll(RegExp(r'<[^>]*>'), '');
  }
  
  /// 日本語文字数をカウント（半角は0.5、全角は1として計算）
  double get japaneseLength {
    double length = 0;
    for (int i = 0; i < this.length; i++) {
      final char = codeUnitAt(i);
      // 半角文字の範囲
      if (char <= 0x7F || (char >= 0xFF61 && char <= 0xFF9F)) {
        length += 0.5;
      } else {
        length += 1;
      }
    }
    return length;
  }
}

/// BuildContext拡張
extension BuildContextExtensions on BuildContext {
  /// テーマデータを取得
  ThemeData get theme => Theme.of(this);
  
  /// 画面サイズを取得
  Size get screenSize => MediaQuery.of(this).size;
  
  /// 画面幅を取得
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// 画面高さを取得
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// レスポンシブ判定
  bool get isMobile => screenWidth < 768;
  bool get isTablet => screenWidth >= 768 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;
  
  /// SafeAreaの上部パディングを取得
  double get topPadding => MediaQuery.of(this).padding.top;
  
  /// SafeAreaの下部パディングを取得
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
}

/// List拡張
extension ListExtensions<T> on List<T> {
  /// 安全なget（インデックス範囲外の場合はnullを返す）
  T? safeGet(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }
  
  /// 重複を除去
  List<T> distinct() {
    return toSet().toList();
  }
}