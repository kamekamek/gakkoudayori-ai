import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitu/features/ai_assistant/presentation/widgets/ai_functions_grid.dart';
import 'package:yutori_kyoshitu/features/ai_assistant/presentation/widgets/ai_function_button.dart';

void main() {
  group('AIFunctionsGrid Tests', () {
    testWidgets('6つのAI機能ボタンが表示される', (WidgetTester tester) async {
      AIFunctionType? pressedType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIFunctionsGrid(
              onFunctionPressed: (type) => pressedType = type,
            ),
          ),
        ),
      );

      // 6つのボタンが表示されることを確認
      expect(find.byType(AIFunctionButton), findsNWidgets(6));

      // 各ボタンが表示されることを確認
      expect(find.text('挨拶文生成'), findsOneWidget);
      expect(find.text('予定作成'), findsOneWidget);
      expect(find.text('文章改善'), findsOneWidget);
      expect(find.text('見出し生成'), findsOneWidget);
      expect(find.text('要約作成'), findsOneWidget);
      expect(find.text('詳細展開'), findsOneWidget);
    });

    testWidgets('ボタンタップでコールバックが呼ばれる', (WidgetTester tester) async {
      AIFunctionType? pressedType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIFunctionsGrid(
              onFunctionPressed: (type) => pressedType = type,
            ),
          ),
        ),
      );

      // 挨拶文生成ボタンをタップ
      await tester.tap(find.text('挨拶文生成'));
      await tester.pump();

      expect(pressedType, equals(AIFunctionType.addGreeting));
    });

    testWidgets('処理中のボタンがローディング表示になる', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIFunctionsGrid(
              processingType: AIFunctionType.rewrite,
              onFunctionPressed: (type) {},
            ),
          ),
        ),
      );

      // 文章改善ボタンが処理中状態になることを確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AI機能タイトルが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIFunctionsGrid(
              onFunctionPressed: (type) {},
            ),
          ),
        ),
      );

      expect(find.text('AI機能'), findsOneWidget);
    });
  });

  group('AIFunctionsDescription Tests', () {
    testWidgets('説明テキストが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AIFunctionsDescription(),
          ),
        ),
      );

      expect(find.text('ワンクリックAI機能'), findsOneWidget);
      expect(find.textContaining('各ボタンをクリックして'), findsOneWidget);
    });
  });

  group('AIFunctionDescriptions Tests', () {
    test('各AI機能の説明が定義されている', () {
      for (final type in AIFunctionType.values) {
        final description = AIFunctionDescriptions.getDescription(type);
        expect(description, isNotEmpty);
        expect(description, isNot(equals('未定義の機能です')));
      }
    });

    test('適切な説明テキストが返される', () {
      expect(
        AIFunctionDescriptions.getDescription(AIFunctionType.addGreeting),
        contains('挨拶文'),
      );
      expect(
        AIFunctionDescriptions.getDescription(AIFunctionType.rewrite),
        contains('改善'),
      );
    });
  });
}
