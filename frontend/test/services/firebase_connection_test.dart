import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitu/core/services/firebase_service.dart';
import 'package:yutori_kyoshitu/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase設定確認テスト', () {
    test('Firebase Web設定が正しく定義されていること', () {
      // Firebase Web設定が存在することを確認
      expect(DefaultFirebaseOptions.web, isNotNull);

      // 必要なフィールドが存在することを確認（Mapからの値取得）
      expect(DefaultFirebaseOptions.web['apiKey'], isNotNull);
      expect(DefaultFirebaseOptions.web['projectId'], isNotNull);
      expect(DefaultFirebaseOptions.web['authDomain'], isNotNull);
      expect(DefaultFirebaseOptions.web['storageBucket'], isNotNull);

      // 値の内容も確認
      expect(DefaultFirebaseOptions.web['apiKey'], equals('mock-web-api-key'));
      expect(DefaultFirebaseOptions.web['projectId'],
          equals('yutori-kyoshitu-mock'));
      expect(DefaultFirebaseOptions.web['authDomain'],
          equals('yutori-kyoshitu-mock.firebaseapp.com'));
      expect(DefaultFirebaseOptions.web['storageBucket'],
          equals('yutori-kyoshitu-mock.appspot.com'));
    });

    test('FirebaseServiceが正しく定義されていること', () {
      // FirebaseServiceクラスが存在することを確認
      expect(FirebaseService.isInitialized, isFalse);
    });

    test('プラットフォーム固有の設定が取得できること', () {
      // currentPlatformが正しく動作することを確認
      final platformConfig = DefaultFirebaseOptions.currentPlatform;
      expect(platformConfig, isNotNull);
      expect(platformConfig['projectId'], isNotNull);
    });
  });
}
