import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitu/core/services/firebase_service.dart';
import 'package:yutori_kyoshitu/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase設定確認', () {
    test('Firebase設定値が正しく設定されている', () {
      final options = DefaultFirebaseOptions.currentPlatform;

      // 個々のプロパティを直接アクセス
      expect(options.apiKey, isNotEmpty);
      expect(options.appId, isNotEmpty);
      expect(options.messagingSenderId, isNotEmpty);
      expect(options.projectId, isNotEmpty);

      // Web用設定も確認
      expect(options.authDomain, isNotEmpty);
      expect(options.storageBucket, isNotEmpty);

      expect(options.measurementId, isNotEmpty);

      expect(options.iosBundleId, isNotEmpty);
    });

    test('プロジェクトIDが正しい形式', () {
      final options = DefaultFirebaseOptions.currentPlatform;
      final projectId = options.projectId;

      // プロジェクトIDの基本的な検証
      expect(projectId, isNotNull);
      expect(projectId, isNotEmpty);
      expect(projectId.length, greaterThan(5));
    });

    test('Firebase Web設定が正しく定義されていること', () {
      // Firebase Web設定が存在することを確認
      expect(DefaultFirebaseOptions.web, isNotNull);

      // 必要なフィールドが存在することを確認（プロパティアクセス）
      expect(DefaultFirebaseOptions.web.apiKey, isNotNull);
      expect(DefaultFirebaseOptions.web.projectId, isNotNull);
      expect(DefaultFirebaseOptions.web.authDomain, isNotNull);
      expect(DefaultFirebaseOptions.web.storageBucket, isNotNull);

      // 値の内容も確認（実際の設定値に基づいて）
      expect(DefaultFirebaseOptions.web.apiKey, isNotEmpty);
      expect(DefaultFirebaseOptions.web.projectId, isNotEmpty);
      expect(DefaultFirebaseOptions.web.authDomain, isNotEmpty);
      expect(DefaultFirebaseOptions.web.storageBucket, isNotEmpty);
    });

    test('FirebaseServiceが正しく定義されていること', () {
      // FirebaseServiceクラスが存在することを確認
      expect(FirebaseService.isInitialized, isFalse);
    });

    test('プラットフォーム固有の設定が取得できること', () {
      // currentPlatformが正しく動作することを確認
      final platformConfig = DefaultFirebaseOptions.currentPlatform;
      expect(platformConfig, isNotNull);
      expect(platformConfig.projectId, isNotNull);
    });
  });
}
