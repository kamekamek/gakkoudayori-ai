import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 学校だよりAIアプリのテキストスタイル定義
/// 教育現場での可読性を重視したタイポグラフィシステム
class AppTextStyles {
  AppTextStyles._();

  // ベースフォントファミリー
  static String get fontFamily => GoogleFonts.notoSansJp().fontFamily!;

  // 見出しスタイル
  static TextStyle get displayLarge => GoogleFonts.notoSansJp(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static TextStyle get displayMedium => GoogleFonts.notoSansJp(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );

  static TextStyle get displaySmall => GoogleFonts.notoSansJp(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  // ヘッドラインスタイル
  static TextStyle get headlineLarge => GoogleFonts.notoSansJp(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
  );

  static TextStyle get headlineMedium => GoogleFonts.notoSansJp(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
  );

  static TextStyle get headlineSmall => GoogleFonts.notoSansJp(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );

  // タイトルスタイル
  static TextStyle get titleLarge => GoogleFonts.notoSansJp(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
  );

  static TextStyle get titleMedium => GoogleFonts.notoSansJp(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
  );

  static TextStyle get titleSmall => GoogleFonts.notoSansJp(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ボディテキストスタイル
  static TextStyle get bodyLarge => GoogleFonts.notoSansJp(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.50,
  );

  static TextStyle get bodyMedium => GoogleFonts.notoSansJp(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static TextStyle get bodySmall => GoogleFonts.notoSansJp(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ラベル・UIテキストスタイル
  static TextStyle get labelLarge => GoogleFonts.notoSansJp(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static TextStyle get labelMedium => GoogleFonts.notoSansJp(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static TextStyle get labelSmall => GoogleFonts.notoSansJp(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // アプリ固有スタイル
  
  /// AppBarタイトル用スタイル
  static TextStyle get appBarTitle => GoogleFonts.notoSansJp(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.20,
  );

  /// ボタンテキスト用スタイル
  static TextStyle get buttonText => GoogleFonts.notoSansJp(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  /// ステータスメッセージ用スタイル
  static TextStyle get statusMessage => GoogleFonts.notoSansJp(
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
}