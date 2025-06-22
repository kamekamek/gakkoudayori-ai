import 'package:flutter/material.dart';
import 'app/app.dart';
import 'config/app_config.dart';

/// 学校だよりAI - エントリーポイント
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 設定の初期化とバリデーション
  AppConfig.printConfig();
  if (!AppConfig.validateConfig()) {
    throw Exception(
        'Invalid configuration. Please check your environment variables.');
  }

  runApp(const GakkouDayoriAiApp());
}
