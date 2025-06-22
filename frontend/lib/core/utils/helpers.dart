import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// ユーティリティヘルパー関数
class AppHelpers {
  /// ランダムなIDを生成
  static String generateId([int length = 8]) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
  
  /// ファイルサイズを人間が読みやすい形式に変換
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
  
  /// デバウンス処理
  static Timer? _debounceTimer;
  static void debounce(Duration delay, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }
  
  /// 画像の拡張子からMIMEタイプを取得
  static String getMimeTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
  
  /// URLが有効かどうかを判定
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }
  
  /// 文字列が空かnullかを判定
  static bool isNullOrEmpty(String? str) {
    return str == null || str.isEmpty;
  }
  
  /// 文字列が空でない場合のみ実行
  static T? ifNotEmpty<T>(String? str, T Function(String) callback) {
    if (isNullOrEmpty(str)) return null;
    return callback(str!);
  }
  
  /// 日本語の文字数制限（半角0.5文字、全角1文字で計算）
  static String truncateJapanese(String text, double maxLength) {
    if (text.isEmpty) return text;
    
    double currentLength = 0;
    int truncateIndex = 0;
    
    for (int i = 0; i < text.length; i++) {
      final char = text.codeUnitAt(i);
      final charLength = (char <= 0x7F || (char >= 0xFF61 && char <= 0xFF9F)) ? 0.5 : 1.0;
      
      if (currentLength + charLength > maxLength) {
        break;
      }
      
      currentLength += charLength;
      truncateIndex = i + 1;
    }
    
    return truncateIndex < text.length ? '${text.substring(0, truncateIndex)}...' : text;
  }
  
  /// 色を16進数文字列に変換
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
  
  /// 16進数文字列を色に変換
  static Color? hexToColor(String hex) {
    try {
      final hexCode = hex.replaceAll('#', '');
      if (hexCode.length == 6) {
        return Color(int.parse('FF$hexCode', radix: 16));
      } else if (hexCode.length == 8) {
        return Color(int.parse(hexCode, radix: 16));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// 日本語処理用のヘルパー
class JapaneseHelpers {
  /// ひらがなからカタカナに変換
  static String hiraganaToKatakana(String text) {
    return text.replaceAllMapped(
      RegExp(r'[ぁ-ゖ]'),
      (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 96),
    );
  }
  
  /// カタカナからひらがなに変換
  static String katakanaToHiragana(String text) {
    return text.replaceAllMapped(
      RegExp(r'[ァ-ヶ]'),
      (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) - 96),
    );
  }
  
  /// 全角から半角に変換
  static String zenkakuToHankaku(String text) {
    return text.replaceAllMapped(
      RegExp(r'[Ａ-Ｚａ-ｚ０-９]'),
      (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) - 0xFEE0),
    );
  }
  
  /// 半角から全角に変換
  static String hankakuToZenkaku(String text) {
    return text.replaceAllMapped(
      RegExp(r'[A-Za-z0-9]'),
      (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 0xFEE0),
    );
  }
}

