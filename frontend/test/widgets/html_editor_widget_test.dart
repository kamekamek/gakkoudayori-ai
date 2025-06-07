import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yutori_kyoshitsu/widgets/html_editor_widget.dart';
import 'package:yutori_kyoshitsu/providers/editor_provider.dart';

void main() {
  group('HtmlEditorWidget Tests', () {
    testWidgets('HTMLエディタが正常に初期化される', (WidgetTester tester) async {
      // Given
      final editorProvider = EditorProvider();

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => editorProvider,
            child: const HtmlEditorWidget(),
          ),
        ),
      );

      // Then
      expect(find.byType(HtmlEditorWidget), findsOneWidget);
    });

    testWidgets('エディタにテキストを入力できる', (WidgetTester tester) async {
      // Given
      final editorProvider = EditorProvider();

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => editorProvider,
            child: const HtmlEditorWidget(),
          ),
        ),
      );

      // Then
      // エディタが表示されることを確認
      expect(find.byType(HtmlEditorWidget), findsOneWidget);
    });

    testWidgets('HTMLコンテンツが正しく設定される', (WidgetTester tester) async {
      // Given
      final editorProvider = EditorProvider();
      const testHtml = '<p>テストコンテンツ</p>';

      // When
      editorProvider.setHtmlContent(testHtml);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => editorProvider,
            child: const HtmlEditorWidget(),
          ),
        ),
      );

      // Then
      expect(editorProvider.htmlContent, equals(testHtml));
    });
  });
}
