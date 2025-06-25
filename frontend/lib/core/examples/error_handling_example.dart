/// エラーハンドリングの使用例とサンプルコード
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../exceptions/app_exceptions.dart';
import '../providers/error_provider.dart';
import '../services/session_recovery_service.dart';
import '../widgets/error_display_widget.dart';
import '../../features/ai_assistant/providers/adk_chat_provider.dart';
import '../../features/editor/providers/preview_provider.dart';
import '../../services/adk_agent_service.dart';

/// エラーハンドリングの使用例を示すサンプルページ
class ErrorHandlingExamplePage extends StatefulWidget {
  const ErrorHandlingExamplePage({super.key});

  @override
  State<ErrorHandlingExamplePage> createState() => _ErrorHandlingExamplePageState();
}

class _ErrorHandlingExamplePageState extends State<ErrorHandlingExamplePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('エラーハンドリング例'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'エラーハンドリングの例',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // エラー表示ウィジェット
            const ErrorDisplayWidget(
              showRetryButton: true,
            ),
            
            const SizedBox(height: 16),
            
            // テスト用ボタン群
            _buildTestButtons(),
            
            const SizedBox(height: 24),
            
            // エラー統計表示
            const ErrorStatsWidget(),
            
            const SizedBox(height: 16),
            
            // エラーリスト表示
            const ErrorListWidget(maxItems: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'エラーテスト',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _testNetworkError(context),
                  child: const Text('ネットワークエラー'),
                ),
                ElevatedButton(
                  onPressed: () => _testApiError(context),
                  child: const Text('APIエラー'),
                ),
                ElevatedButton(
                  onPressed: () => _testAudioError(context),
                  child: const Text('音声エラー'),
                ),
                ElevatedButton(
                  onPressed: () => _testValidationError(context),
                  child: const Text('バリデーションエラー'),
                ),
                ElevatedButton(
                  onPressed: () => _testSessionError(context),
                  child: const Text('セッションエラー'),
                ),
                ElevatedButton(
                  onPressed: () => _testRetryOperation(context),
                  child: const Text('リトライテスト'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _testNetworkError(BuildContext context) {
    final errorProvider = context.read<ErrorProvider>();
    errorProvider.reportError(
      NetworkException.timeout(),
      context: 'Network error test',
    );
  }

  void _testApiError(BuildContext context) {
    final errorProvider = context.read<ErrorProvider>();
    errorProvider.reportError(
      ApiException.serverError('サーバーでエラーが発生しました'),
      context: 'API error test',
    );
  }

  void _testAudioError(BuildContext context) {
    final errorProvider = context.read<ErrorProvider>();
    errorProvider.reportError(
      AudioException.permissionDenied(),
      context: 'Audio error test',
    );
  }

  void _testValidationError(BuildContext context) {
    final errorProvider = context.read<ErrorProvider>();
    errorProvider.reportError(
      ValidationException.required('テストフィールド'),
      context: 'Validation error test',
    );
  }

  void _testSessionError(BuildContext context) {
    final errorProvider = context.read<ErrorProvider>();
    errorProvider.reportError(
      SessionException.expired(),
      context: 'Session error test',
    );
  }

  void _testRetryOperation(BuildContext context) async {
    final errorProvider = context.read<ErrorProvider>();
    
    try {
      await errorProvider.retryOperation(
        () async {
          // 模擬的な失敗操作
          await Future.delayed(const Duration(seconds: 1));
          throw NetworkException.timeout();
        },
        context: 'Retry operation test',
      );
    } catch (e) {
      // エラーは既にErrorProviderで処理されている
      debugPrint('Retry operation failed as expected: $e');
    }
  }
}

/// Providerの設定例
class ErrorHandlingProviderExample extends StatelessWidget {
  const ErrorHandlingProviderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // エラープロバイダーを最初に定義
        ChangeNotifierProvider(
          create: (context) => ErrorProvider(),
        ),
        
        // セッション復旧サービス
        Provider(
          create: (context) => SessionRecoveryService(
            errorProvider: context.read<ErrorProvider>(),
          ),
        ),
        
        // ADKサービス
        Provider(
          create: (context) => AdkAgentService(),
        ),
        
        // プレビュープロバイダー（エラープロバイダーに依存）
        ChangeNotifierProvider(
          create: (context) => PreviewProvider(
            errorProvider: context.read<ErrorProvider>(),
          ),
        ),
        
        // ADKチャットプロバイダー（複数のサービスに依存）
        ChangeNotifierProvider(
          create: (context) => AdkChatProvider(
            adkService: context.read<AdkAgentService>(),
            errorProvider: context.read<ErrorProvider>(),
            userId: 'example_user',
          ),
        ),
      ],
      child: const ErrorHandlingExamplePage(),
    );
  }
}

/// エラーハンドリングのベストプラクティス例
class ErrorHandlingBestPractices {
  /// 非同期操作でのエラーハンドリング例
  static Future<void> exampleAsyncOperation(ErrorProvider errorProvider) async {
    try {
      // 何らかの非同期操作
      await _simulateAsyncOperation();
    } catch (error, stackTrace) {
      errorProvider.reportError(
        error,
        stackTrace: stackTrace,
        context: 'Example async operation',
      );
      rethrow; // 必要に応じて再スロー
    }
  }

  /// リトライ付き操作の例
  static Future<String> exampleRetryOperation(ErrorProvider errorProvider) async {
    return await errorProvider.retryOperation(
      () async {
        // リトライ可能な操作
        final result = await _simulateRetryableOperation();
        if (result == null) {
          throw ApiException.serverError('Operation failed');
        }
        return result;
      },
      context: 'Example retry operation',
    );
  }

  /// バリデーション付きフォーム処理の例
  static Future<void> exampleFormValidation(
    Map<String, String> formData,
    ErrorProvider errorProvider,
  ) async {
    try {
      // フィールドバリデーション
      if (formData['name']?.isEmpty ?? true) {
        throw ValidationException.required('name');
      }
      
      if (formData['email']?.contains('@') != true) {
        throw ValidationException.invalidFormat('email', 'valid email format');
      }

      // API呼び出し
      await _submitForm(formData);
      
    } catch (error, stackTrace) {
      errorProvider.reportError(
        error,
        stackTrace: stackTrace,
        context: 'Form validation and submission',
      );
      rethrow;
    }
  }

  /// セッション復旧の例
  static Future<void> exampleSessionRecovery(
    SessionRecoveryService recoveryService,
    AdkChatProvider chatProvider,
  ) async {
    try {
      final recoveredData = await recoveryService.attemptAutoRecovery();
      
      if (recoveredData != null) {
        // セッションデータを復元
        chatProvider.clearSession(); // 現在のセッションをクリア
        // 復旧データの適用は実際の実装に応じて
        debugPrint('Session recovered: ${recoveredData.sessionId}');
      }
    } catch (error) {
      debugPrint('Session recovery failed: $error');
      // 復旧失敗は通常ユーザーに表示しない
    }
  }

  /// エラー通知の例
  static void exampleErrorNotification(
    BuildContext context,
    AppException exception,
  ) {
    // スナックバーでの表示
    ErrorSnackBar.show(
      context,
      exception,
      onRetry: exception.isRetryable 
        ? () => debugPrint('Retry requested')
        : null,
    );
  }

  // 模擬的なヘルパーメソッド
  static Future<void> _simulateAsyncOperation() async {
    await Future.delayed(const Duration(seconds: 1));
    // 何らかの処理
  }

  static Future<String?> _simulateRetryableOperation() async {
    await Future.delayed(const Duration(seconds: 1));
    // 模擬的に時々失敗する操作
    if (DateTime.now().millisecondsSinceEpoch % 3 == 0) {
      return 'Success!';
    }
    return null; // 失敗
  }

  static Future<void> _submitForm(Map<String, String> formData) async {
    await Future.delayed(const Duration(seconds: 1));
    // フォーム送信の模擬
  }
}

/// 使用方法のドキュメント
/// 
/// ## 基本的な使用方法
/// 
/// 1. **ErrorProviderの設定**
/// ```dart
/// ChangeNotifierProvider(
///   create: (context) => ErrorProvider(),
///   child: MyApp(),
/// )
/// ```
/// 
/// 2. **エラーの報告**
/// ```dart
/// final errorProvider = context.read<ErrorProvider>();
/// errorProvider.reportError(
///   NetworkException.timeout(),
///   context: 'API call failed',
/// );
/// ```
/// 
/// 3. **リトライ操作**
/// ```dart
/// await errorProvider.retryOperation(
///   () => myApiCall(),
///   context: 'Calling API',
/// );
/// ```
/// 
/// 4. **UI でのエラー表示**
/// ```dart
/// const ErrorDisplayWidget(
///   showRetryButton: true,
/// )
/// ```
/// 
/// ## カスタムエラーの作成
/// 
/// ```dart
/// class MyCustomException extends AppException {
///   const MyCustomException({
///     required super.message,
///     super.code = 'MY_CUSTOM_ERROR',
///     super.isRetryable = false,
///     super.severity = 3,
///   });
/// 
///   @override
///   String get userMessage => 'カスタムエラーが発生しました';
/// }
/// ```