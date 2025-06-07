import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitsu/providers/editor_provider.dart';

void main() {
  group('EditorProvider Tests', () {
    late EditorProvider editorProvider;

    setUp(() {
      editorProvider = EditorProvider();
    });

    test('初期状態が正しく設定される', () {
      // Then
      expect(editorProvider.htmlContent, isNotEmpty); // 初期コンテンツがある
      expect(editorProvider.isLoading, isFalse);
      expect(editorProvider.errorMessage, isNull);
    });

    test('HTMLコンテンツが正しく設定される', () {
      // Given
      const testHtml = '<p>テストコンテンツ</p>';

      // When
      editorProvider.setHtmlContent(testHtml);

      // Then
      expect(editorProvider.htmlContent, equals(testHtml));
    });

    test('ローディング状態が正しく管理される', () {
      // When
      editorProvider.setLoading(true);

      // Then
      expect(editorProvider.isLoading, isTrue);

      // When
      editorProvider.setLoading(false);

      // Then
      expect(editorProvider.isLoading, isFalse);
    });

    test('エラー状態が正しく管理される', () {
      // Given
      const errorMessage = 'テストエラー';

      // When
      editorProvider.setError(errorMessage);

      // Then
      expect(editorProvider.errorMessage, equals(errorMessage));
    });

    test('エラーがクリアされる', () {
      // Given
      editorProvider.setError('エラー');

      // When
      editorProvider.clearError();

      // Then
      expect(editorProvider.errorMessage, isNull);
    });
  });
}
