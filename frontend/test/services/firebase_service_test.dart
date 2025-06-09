import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitu/core/services/firebase_service.dart';

// 簡略化したテストケース
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('FirebaseServiceクラスのテスト', () {
    // テスト前に初期化状態を確認
    setUp(() {
      // テスト環境では実際のFirebase初期化は行われない
      // そのため、ここではクラスの動作のみをテスト
    });
    
    test('isInitializedが初期値ではfalseを返すこと', () {
      // 初期状態ではisInitializedがfalseであることを確認
      expect(FirebaseService.isInitialized, false);
    });

    test('初期化前にgetInstanceを呼ぶとエラーになること', () {
      // 初期化前にinstanceを取得しようとするとエラーが発生することを確認
      expect(() => FirebaseService.instance, throwsA(isA<StateError>()));
    });
  });
}
