class AppConfig {
  // 環境変数から取得、デフォルト値を設定
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081/api/v1/ai',
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
    print('🔧 App Configuration:');
    print('   Environment: $environment');
    print('   API Base URL: $apiBaseUrl');
    print('   Is Development: $isDevelopment');
    print('   Is Production: $isProduction');
  }
}
