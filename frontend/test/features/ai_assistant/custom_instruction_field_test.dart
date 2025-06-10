import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitu/features/ai_assistant/presentation/widgets/custom_instruction_field.dart';

void main() {
  group('CustomInstructionField Tests', () {
    testWidgets('カスタム指示入力フィールドが正しく表示される', (WidgetTester tester) async {
      String currentInstruction = '';
      bool submitWasCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomInstructionField(
              instruction: currentInstruction,
              onChanged: (value) => currentInstruction = value,
              onSubmit: () => submitWasCalled = true,
            ),
          ),
        ),
      );

      // テキストフィールドとボタンが表示されることを確認
      expect(find.byType(CustomInstructionField), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('生成'), findsOneWidget);
    });

    testWidgets('プレースホルダーテキストが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomInstructionField(
              instruction: '',
              onChanged: (value) {},
              onSubmit: () {},
            ),
          ),
        ),
      );

      // プレースホルダーが表示されることを確認
      expect(find.text('例：もっと親しみやすい文章にして'), findsOneWidget);
    });

    testWidgets('テキスト入力でonChangedが呼ばれる', (WidgetTester tester) async {
      String capturedValue = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomInstructionField(
              instruction: '',
              onChanged: (value) => capturedValue = value,
              onSubmit: () {},
            ),
          ),
        ),
      );

      // テキストを入力
      await tester.enterText(find.byType(TextField), 'テスト指示');
      await tester.pump();

      // onChangedが呼ばれて値が更新されることを確認
      expect(capturedValue, equals('テスト指示'));
    });

    testWidgets('生成ボタンタップでonSubmitが呼ばれる', (WidgetTester tester) async {
      bool submitWasCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomInstructionField(
              instruction: 'テスト指示',
              onChanged: (value) {},
              onSubmit: () => submitWasCalled = true,
            ),
          ),
        ),
      );

      // 生成ボタンをタップ
      await tester.tap(find.text('生成'));
      await tester.pump();

      // onSubmitが呼ばれることを確認
      expect(submitWasCalled, isTrue);
    });

    testWidgets('Enterキーでサブミットされる', (WidgetTester tester) async {
      bool submitWasCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomInstructionField(
              instruction: 'テスト指示',
              onChanged: (value) {},
              onSubmit: () => submitWasCalled = true,
            ),
          ),
        ),
      );

      // フィールドにフォーカスしてEnterキーを押す
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // onSubmitが呼ばれることを確認
      expect(submitWasCalled, isTrue);
    });

    testWidgets('処理中は生成ボタンが無効になる', (WidgetTester tester) async {
      bool submitWasCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomInstructionField(
              instruction: 'テスト指示',
              onChanged: (value) {},
              onSubmit: () => submitWasCalled = true,
              isProcessing: true,
            ),
          ),
        ),
      );

      // 生成ボタンを探して確認（処理中は無効化されている）
      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);

      // ボタンが無効化されているので、タップしても反応しない
      await tester.tap(button);
      await tester.pump();

      // onSubmitが呼ばれないことを確認
      expect(submitWasCalled, isFalse);
    });

    testWidgets('処理中はローディング表示になる', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomInstructionField(
              instruction: 'テスト指示',
              onChanged: (value) {},
              onSubmit: () {},
              isProcessing: true,
            ),
          ),
        ),
      );

      // ローディングインジケーターが表示されることを確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('サンプル指示が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomInstructionField(
              instruction: '',
              onChanged: (value) {},
              onSubmit: () {},
              showSamples: true,
            ),
          ),
        ),
      );

      // サンプル指示が表示されることを確認
      expect(find.text('サンプル指示'), findsOneWidget);
      expect(find.text('もっと親しみやすい文章にして'), findsOneWidget);
    });

    testWidgets('サンプル指示タップで入力される', (WidgetTester tester) async {
      String capturedValue = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomInstructionField(
              instruction: '',
              onChanged: (value) => capturedValue = value,
              onSubmit: () {},
              showSamples: true,
            ),
          ),
        ),
      );

      // サンプル指示をタップ
      await tester.tap(find.text('もっと親しみやすい文章にして'));
      await tester.pump();

      // サンプル文言が入力されることを確認
      expect(capturedValue, equals('もっと親しみやすい文章にして'));
    });

    testWidgets('最大文字数チェックが機能する', (WidgetTester tester) async {
      String currentInstruction = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomInstructionField(
              instruction: currentInstruction,
              onChanged: (value) => currentInstruction = value,
              onSubmit: () {},
              maxLength: 200,
            ),
          ),
        ),
      );

      // 201文字入力してエラーを発生させる
      final longText = 'あ' * 201;
      await tester.enterText(find.byType(TextField), longText);
      await tester.pump();

      // 文字数超過エラーが表示されることを確認
      expect(find.text('200文字以内で入力してください'), findsOneWidget);
    });
  });
}
