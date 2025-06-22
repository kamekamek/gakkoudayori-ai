import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'responsive_main.dart' as responsive;
import 'config/app_config.dart';

/// 学校だよりAI - レスポンシブ対応版エントリーポイント
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化（Web環境）
  try {
    await Firebase.initializeApp();
    print('✅ Firebase初期化成功');
  } catch (e) {
    print('⚠️ Firebase初期化エラー: $e');
    // Firebase設定がない場合でも続行
  }

  // 設定の初期化とバリデーション
  AppConfig.printConfig();
  if (!AppConfig.validateConfig()) {
    throw Exception(
        'Invalid configuration. Please check your environment variables.');
  }

  runApp(responsive.GakkouDayoriAiApp());
}
