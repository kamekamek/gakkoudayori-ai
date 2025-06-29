import 'package:flutter/foundation.dart';

class AppConfig {
  // 環境変数から取得、デフォルト値を設定
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // 本番環境URL（Cloud Run等）
  static const String prodApiBaseUrl = String.fromEnvironment(
    'PROD_API_BASE_URL',
    defaultValue: 'https://gakkoudayori-backend-xxxxxxxxxxxx-xx.a.run.app',
  );

  // WebSocket URL（開発用）
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL', 
    defaultValue: 'ws://localhost:8081',
  );

  // WebSocket URL（本番用）
  static const String prodWsBaseUrl = String.fromEnvironment(
    'PROD_WS_BASE_URL',
    defaultValue: 'wss://gakkoudayori-backend-xxxxxxxxxxxx-xx.a.run.app',
  );

  // 環境判定
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';

  // 環境に応じたURL取得
  static String get currentApiBaseUrl {
    switch (environment) {
      case 'production':
        return prodApiBaseUrl;
      case 'staging':
        return prodApiBaseUrl; // staging環境も本番URLを使用
      case 'development':
      default:
        return apiBaseUrl;
    }
  }

  static String get currentWsBaseUrl {
    switch (environment) {
      case 'production':
        return prodWsBaseUrl;
      case 'staging':
        return prodWsBaseUrl;
      case 'development':
      default:
        return wsBaseUrl;
    }
  }

  // API完全URL生成
  static String get apiV1BaseUrl => '${currentApiBaseUrl}/api/v1';
  static String get wsV1BaseUrl => '${currentWsBaseUrl}/api/v1';

  // デバッグ情報
  static void printConfig() {
    if (kDebugMode) {
      debugPrint('🔧 App Configuration:');
      debugPrint('   Environment: $environment');
      debugPrint('   Current API Base URL: $currentApiBaseUrl');
      debugPrint('   Current WS Base URL: $currentWsBaseUrl');
      debugPrint('   API v1 URL: $apiV1BaseUrl');
      debugPrint('   WS v1 URL: $wsV1BaseUrl');
      debugPrint('   Is Development: $isDevelopment');
      debugPrint('   Is Production: $isProduction');
      debugPrint('   Is Staging: $isStaging');
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
