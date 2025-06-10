// Yutori Kyoshitu Flutter widget test.
// 学校だよりAIアプリの基本ウィジェットテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yutori_kyoshitu/core/theme/app_theme.dart';

void main() {
  testWidgets('MaterialApp基本設定テスト', (WidgetTester tester) async {
    // シンプルなMaterialAppを直接テスト
    await tester.pumpWidget(
      MaterialApp(
        title: '学校だよりAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const Scaffold(
          body: Center(child: Text('テスト画面')),
        ),
      ),
    );

    // MaterialAppが存在することを確認
    expect(find.byType(MaterialApp), findsOneWidget);

    // テスト用のテキストが表示されることを確認
    expect(find.text('テスト画面'), findsOneWidget);

    // Scaffoldが存在することを確認
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('AppThemeテーマ設定テスト', (WidgetTester tester) async {
    // AppThemeを使用したテーマ設定テスト
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: Scaffold(
          appBar: AppBar(title: Text('テーマテスト')),
          body: Center(child: Text('テーマが正常に適用されました')),
        ),
      ),
    );

    // AppBarが存在することを確認
    expect(find.byType(AppBar), findsOneWidget);

    // テーマが適用されたテキストが表示されることを確認
    expect(find.text('テーマテスト'), findsOneWidget);
    expect(find.text('テーマが正常に適用されました'), findsOneWidget);
  });

  test('AppThemeライト・ダークテーマが作成できること', () {
    // AppThemeのテーマデータが正常に作成されることを確認
    final lightTheme = AppTheme.light();
    final darkTheme = AppTheme.dark();

    expect(lightTheme, isNotNull);
    expect(darkTheme, isNotNull);
    expect(lightTheme.brightness, equals(Brightness.light));
    expect(darkTheme.brightness, equals(Brightness.dark));
  });
}
