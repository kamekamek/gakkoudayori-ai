import 'package:flutter/material.dart';
import 'responsive_main.dart' as responsive;
import 'config/app_config.dart';

/// 学級通信AI - レスポンシブ対応版エントリーポイント
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 設定の初期化とバリデーション
  AppConfig.printConfig();
  if (!AppConfig.validateConfig()) {
    throw Exception(
        'Invalid configuration. Please check your environment variables.');
  }

  runApp(responsive.YutoriKyoshituApp());
}
