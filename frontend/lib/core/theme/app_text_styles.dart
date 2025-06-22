import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 学校だよりAIアプリのテキストスタイル定義
/// 教育現場での可読性を重視したタイポグラフィシステム
class AppTextStyles {
  AppTextStyles._();

  // ベースフォントファミリー（フォールバック付き）
  static String get fontFamily => GoogleFonts.notoSansJp().fontFamily ?? 'Hiragino Kaku Gothic ProN';

  // 見出しスタイル
  static TextStyle get displayLarge => _safeGoogleFont(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static TextStyle get displayMedium => _safeGoogleFont(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );

  static TextStyle get displaySmall => _safeGoogleFont(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  // ヘッドラインスタイル
  static TextStyle get headlineLarge => _safeGoogleFont(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
  );

  static TextStyle get headlineMedium => _safeGoogleFont(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
  );

  static TextStyle get headlineSmall => _safeGoogleFont(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );

  // タイトルスタイル
  static TextStyle get titleLarge => _safeGoogleFont(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
  );

  static TextStyle get titleMedium => _safeGoogleFont(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
  );

  static TextStyle get titleSmall => _safeGoogleFont(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ボディテキストスタイル
  static TextStyle get bodyLarge => _safeGoogleFont(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.50,
  );

  static TextStyle get bodyMedium => _safeGoogleFont(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static TextStyle get bodySmall => _safeGoogleFont(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ラベル・UIテキストスタイル
  static TextStyle get labelLarge => _safeGoogleFont(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static TextStyle get labelMedium => _safeGoogleFont(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static TextStyle get labelSmall => _safeGoogleFont(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // アプリ固有スタイル
  
  /// AppBarタイトル用スタイル
  static TextStyle get appBarTitle => _safeGoogleFont(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.20,
  );

  /// ボタンテキスト用スタイル
  static TextStyle get buttonText => _safeGoogleFont(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  /// ステータスメッセージ用スタイル
  static TextStyle get statusMessage => _safeGoogleFont(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  /// 完全なTextThemeを生成する
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );

  /// Google Fontsの安全なロード（フォールバック付き）
  static TextStyle _safeGoogleFont({
    required double fontSize,
    required FontWeight fontWeight,
    required double letterSpacing,
    required double height,
  }) {
    try {
      return GoogleFonts.notoSansJp(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
      );
    } catch (e) {
      // ネットワークエラー時のフォールバック
      return TextStyle(
        fontFamily: 'Hiragino Kaku Gothic ProN',
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
  }
}