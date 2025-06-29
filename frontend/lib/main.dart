import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:html' as html;
import 'app/app.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';
import 'services/google_auth_service.dart';

/// デモモードの状態を管理するプロバイダー
final demoModeProvider = StateProvider<bool>((ref) {
  // URLパラメータから demo=true を検出
  final currentUrl = html.window.location.href;
  final uri = Uri.parse(currentUrl);
  return uri.queryParameters['demo'] == 'true';
});

/// 学校だよりAI - エントリーポイント
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // デモモードかどうかをチェック
  final currentUrl = html.window.location.href;
  final uri = Uri.parse(currentUrl);
  final isDemoMode = uri.queryParameters['demo'] == 'true';

  if (isDemoMode) {
    debugPrint('🎬 デモモードで起動中...');
    runApp(
      const ProviderScope(
        child: GakkouDayoriAiApp(),
      ),
    );
    return;
  }

  try {
    // Firebase初期化
    debugPrint('🔥 Firebase初期化を開始...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase初期化完了');

    // Google Sign-In初期化
    debugPrint('🔑 Google Sign-In初期化を開始...');
    GoogleAuthService.initialize();
    debugPrint('✅ Google Sign-In初期化完了');

    // 設定の初期化とバリデーション
    debugPrint('⚙️ 設定の初期化とバリデーション...');
    AppConfig.printConfig();
    if (!AppConfig.validateConfig()) {
      throw Exception(
          'Invalid configuration. Please check your environment variables.');
    }
    debugPrint('✅ 設定バリデーション完了');

    debugPrint('🚀 アプリケーション起動...');
    runApp(
      const ProviderScope(
        child: GakkouDayoriAiApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('❌ アプリケーション初期化エラー: $e');
    debugPrint('スタックトレース: $stackTrace');
    
    // エラー画面を表示
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('アプリケーション初期化エラー'),
                const SizedBox(height: 8),
                Text(e.toString()),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('再試行'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
