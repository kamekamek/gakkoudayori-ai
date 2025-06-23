import 'package:flutter/material.dart';

/// 学校だよりAIアプリのカラーパレット
/// 教育現場にふさわしい温かみのある色調を基調としたデザインシステム
class AppColors {
  AppColors._();

  // プライマリカラー（メインブランドカラー）
  static const Color primary = Color(0xFF2196F3); // Material Blue
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1976D2);

  // セカンダリカラー（アクセント）
  static const Color secondary = Color(0xFFFF9800); // Orange
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFF57C00);

  // 学校・教育テーマカラー
  static const Color education = Color(0xFF4CAF50); // Green
  static const Color educationLight = Color(0xFF81C784);
  static const Color educationDark = Color(0xFF388E3C);

  // 機能別カラー
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // ニュートラルカラー
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  
  // テキストカラー
  static const Color onBackground = Color(0xFF212121);
  static const Color onSurface = Color(0xFF424242);
  static const Color onSurfaceVariant = Color(0xFF757575);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;

  // 録音関連カラー
  static const Color recording = Color(0xFFF44336); // Red
  static const Color recordingLight = Color(0xFFE57373);
  static const Color recordingBackground = Color(0xFFFFEBEE);

  // プレビューエリア
  static const Color previewBackground = Color(0xFFF5F5F5);
  static const Color previewBorder = Color(0xFFE0E0E0);

  // 影・エレベーション
  static const Color shadow = Color(0x1F000000);
  static const Color shadowLight = Color(0x0F000000);

  /// ColorSchemeを生成する
  static ColorScheme get colorScheme => const ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    secondary: secondary,
    onSecondary: onSecondary,
    tertiary: education,
    onTertiary: Colors.white,
    error: error,
    onError: Colors.white,
    surface: surface,
    onSurface: onSurface,
    onBackground: onBackground,
  );
}