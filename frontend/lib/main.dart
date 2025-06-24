import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' show window;
import 'app/app.dart';
import 'config/app_config.dart';

/// 学校だよりAI - エントリーポイント
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // URLからデモモードの設定を確認
  final isDemo = _checkDemoMode();
  
  if (isDemo) {
    // デモモード：デバッグメッセージのみ表示（本番では非表示）
    if (kDebugMode) {
      debugPrint('🎭 [DEMO MODE] Starting in demo mode for video recording');
    }
    runApp(const GakkouDayoriAiApp(isDemo: true));
  } else {
    // 通常モード：設定の初期化とバリデーション
    AppConfig.printConfig();
    if (!AppConfig.validateConfig()) {
      throw Exception(
          'Invalid configuration. Please check your environment variables.');
    }
    runApp(const GakkouDayoriAiApp(isDemo: false));
  }
}

/// URLパラメータからデモモードを判定
bool _checkDemoMode() {
  if (kIsWeb) {
    try {
      final uri = Uri.parse(window.location.href);
      return uri.queryParameters['demo'] == 'true' || 
             uri.queryParameters['mock'] == 'true' ||
             uri.path.contains('/demo');
    } catch (e) {
      debugPrint('Failed to parse URL for demo mode: $e');
      return false;
    }
  }
  return false;
}
