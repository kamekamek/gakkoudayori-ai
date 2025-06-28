import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';
import 'services/google_auth_service.dart';

/// 学校だよりAI - エントリーポイント
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Google Sign-In初期化
  GoogleAuthService.initialize();

  // 設定の初期化とバリデーション
  AppConfig.printConfig();
  if (!AppConfig.validateConfig()) {
    throw Exception(
        'Invalid configuration. Please check your environment variables.');
  }

  runApp(
    const ProviderScope(
      child: GakkouDayoriAiApp(),
    ),
  );
}
