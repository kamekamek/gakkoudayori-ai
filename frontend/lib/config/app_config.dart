import 'package:flutter/foundation.dart';

class AppConfig {
  // 環境変数から取得、デフォルト値を設定
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081/api/v1',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // 環境判定
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';

  // デバッグ情報
  static void printConfig() {
    if (kDebugMode) {
      debugPrint('🔧 App Configuration:');
      debugPrint('   Environment: $environment');
      debugPrint('   API Base URL: $apiBaseUrl');
      debugPrint('   Is Development: $isDevelopment');
      debugPrint('   Is Production: $isProduction');
    }
  }

  // 設定の妥当性チェック
  static bool validateConfig() {
    if (apiBaseUrl.isEmpty) {
      if (kDebugMode) debugPrint('❌ Error: API_BASE_URL is not set');
      return false;
    }

    if (!apiBaseUrl.startsWith('http')) {
      if (kDebugMode)
        debugPrint('❌ Error: API_BASE_URL must start with http:// or https://');
      return false;
    }

    if (environment.isEmpty) {
      if (kDebugMode) debugPrint('❌ Error: ENVIRONMENT is not set');
      return false;
    }

    if (kDebugMode) debugPrint('✅ Configuration is valid');
    return true;
  }

  // 環境別の追加設定
  static bool get enableDebugLogs => isDevelopment;
  static bool get enableAnalytics => isProduction;
  static Duration get apiTimeout =>
      isDevelopment ? const Duration(seconds: 30) : const Duration(seconds: 10);
}
