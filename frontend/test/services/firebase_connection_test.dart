import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitu/core/services/firebase_service.dart';
import 'package:yutori_kyoshitu/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Firebase設定確認テスト', () {
    test('Firebase Web設定が正しく定義されていること', () {
      // Firebase Web設定が存在することを確認
      expect(DefaultFirebaseOptions.web, isNotNull);
      
      // 必要なフィールドが存在することを確認
      expect(DefaultFirebaseOptions.web.apiKey, isNotNull);
      expect(DefaultFirebaseOptions.web.projectId, isNotNull);
      expect(DefaultFirebaseOptions.web.authDomain, isNotNull);
      expect(DefaultFirebaseOptions.web.storageBucket, isNotNull);
    });
    
    test('FirebaseServiceが正しく定義されていること', () {
      // FirebaseServiceクラスが存在することを確認
      expect(FirebaseService.isInitialized, isFalse);
    });
  });
}
