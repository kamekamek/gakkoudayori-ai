import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitu/features/ai_assistant/presentation/widgets/ai_function_button.dart';

void main() {
  group('AIFunctionButton Tests', () {
    testWidgets('AI機能ボタンが正しく表示される', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIFunctionButton(
              title: '挨拶文生成',
              icon: Icons.waving_hand,
              functionType: AIFunctionType.addGreeting,
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      // ボタンが表示されることを確認
      expect(find.byType(AIFunctionButton), findsOneWidget);
      expect(find.text('挨拶文生成'), findsOneWidget);
      expect(find.byIcon(Icons.waving_hand), findsOneWidget);
    });

    testWidgets('ボタンタップでコールバックが呼ばれる', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIFunctionButton(
              title: '予定作成',
              icon: Icons.calendar_today,
              functionType: AIFunctionType.addSchedule,
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      // ボタンをタップ
      await tester.tap(find.byType(AIFunctionButton));
      await tester.pump();

      // コールバックが呼ばれたことを確認
      expect(wasPressed, isTrue);
    });

    testWidgets('処理中はローディング表示になる', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIFunctionButton(
              title: '文章改善',
              icon: Icons.auto_fix_high,
              functionType: AIFunctionType.rewrite,
              onPressed: () {},
              isProcessing: true,
            ),
          ),
        ),
      );

      // ローディングインジケーターが表示されることを確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.auto_fix_high), findsNothing);
    });

    testWidgets('処理中はボタンが無効になる', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIFunctionButton(
              title: '見出し生成',
              icon: Icons.title,
              functionType: AIFunctionType.generateHeading,
              onPressed: () => wasPressed = true,
              isProcessing: true,
            ),
          ),
        ),
      );

      // ボタンをタップしてもコールバックが呼ばれないことを確認
      await tester.tap(find.byType(AIFunctionButton));
      await tester.pump();

      expect(wasPressed, isFalse);
    });

    testWidgets('異なるボタンタイプが正しく表示される', (WidgetTester tester) async {
      final buttonConfigs = [
        {
          'title': '挨拶文生成',
          'icon': Icons.waving_hand,
          'type': AIFunctionType.addGreeting
        },
        {
          'title': '予定作成',
          'icon': Icons.calendar_today,
          'type': AIFunctionType.addSchedule
        },
        {
          'title': '文章改善',
          'icon': Icons.auto_fix_high,
          'type': AIFunctionType.rewrite
        },
        {
          'title': '見出し生成',
          'icon': Icons.title,
          'type': AIFunctionType.generateHeading
        },
        {
          'title': '要約作成',
          'icon': Icons.summarize,
          'type': AIFunctionType.summarize
        },
        {
          'title': '詳細展開',
          'icon': Icons.expand_more,
          'type': AIFunctionType.expand
        },
      ];

      for (var config in buttonConfigs) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AIFunctionButton(
                title: config['title'] as String,
                icon: config['icon'] as IconData,
                functionType: config['type'] as AIFunctionType,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text(config['title'] as String), findsOneWidget);
        expect(find.byIcon(config['icon'] as IconData), findsOneWidget);

        await tester.pumpWidget(Container()); // Clear widget tree
      }
    });
  });
}
