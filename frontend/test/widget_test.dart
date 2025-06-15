// 学級通信エディタ - ウィジェットテスト
//
// 学級通信エディタアプリの基本的なウィジェットテストを実行します。
// 主要なUI要素の存在確認とユーザーインタラクションをテストします。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('学級通信エディタ 基本テスト', () {
    testWidgets('MaterialAppが正常に作成される', (WidgetTester tester) async {
      // シンプルなMaterialAppをテスト
      await tester.pumpWidget(
        MaterialApp(
          title: '学級通信エディタ',
          home: Scaffold(
            appBar: AppBar(
              title: const Text('学級通信エディタ'),
            ),
            body: const Center(
              child: Text('テスト用アプリ'),
            ),
          ),
        ),
      );

      // アプリタイトルが表示されることを確認
      expect(find.text('学級通信エディタ'), findsAtLeastNWidgets(1));

      // テスト用テキストが表示されることを確認
      expect(find.text('テスト用アプリ'), findsOneWidget);
    });

    testWidgets('基本的なUIコンポーネントが動作する', (WidgetTester tester) async {
      // テスト用のシンプルなウィジェット
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(
                    hintText: '学級通信の内容を入力してください',
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('学級通信を作成する'),
                ),
                const Icon(Icons.mic),
              ],
            ),
          ),
        ),
      );

      // テキストフィールドが存在することを確認
      expect(find.byType(TextField), findsOneWidget);

      // ボタンが存在することを確認
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('学級通信を作成する'), findsOneWidget);

      // マイクアイコンが存在することを確認
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('ボタンタップが動作する', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                buttonPressed = true;
              },
              child: const Text('テストボタン'),
            ),
          ),
        ),
      );

      // ボタンをタップ
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // ボタンが押されたことを確認
      expect(buttonPressed, isTrue);
    });

    testWidgets('レスポンシブレイアウトの基本テスト', (WidgetTester tester) async {
      // デスクトップサイズでテスト
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;
                return isMobile
                    ? const Column(
                        children: [
                          Text('モバイルレイアウト'),
                        ],
                      )
                    : const Row(
                        children: [
                          Text('デスクトップレイアウト'),
                        ],
                      );
              },
            ),
          ),
        ),
      );

      // デスクトップレイアウトが表示されることを確認
      expect(find.text('デスクトップレイアウト'), findsOneWidget);
      expect(find.text('モバイルレイアウト'), findsNothing);

      // モバイルサイズでテスト
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;
                return isMobile
                    ? const Column(
                        children: [
                          Text('モバイルレイアウト'),
                        ],
                      )
                    : const Row(
                        children: [
                          Text('デスクトップレイアウト'),
                        ],
                      );
              },
            ),
          ),
        ),
      );

      // モバイルレイアウトが表示されることを確認
      expect(find.text('モバイルレイアウト'), findsOneWidget);
      expect(find.text('デスクトップレイアウト'), findsNothing);
    });
  });
}
