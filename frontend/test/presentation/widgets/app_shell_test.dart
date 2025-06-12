import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitu/features/layout/presentation/widgets/app_shell.dart';

// テスト用の固定文字列
// デフォルトのタイトル
const String appTitle = 'ゆとり職員室';
// 各カラム用のテキスト
const String editText = 'ホーム';
const String previewTitleText = 'プレビュー';

// テスト用のナビゲーション項目
final testNavigationItems = [
  NavigationItem(
    title: 'ホーム',
    icon: Icons.home,
    page: const Text('ホームページ'),
    tooltip: 'ホーム画面',
  ),
  NavigationItem(
    title: '設定',
    icon: Icons.settings,
    page: const Text('設定ページ'),
    tooltip: 'アプリ設定',
  ),
];

void main() {
  group('AppShell Widget テスト', () {
    testWidgets('デスクトップモードで3カラムレイアウトが表示されるか', (WidgetTester tester) async {
      // 幅の広いデスクトップサイズを設定
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      
      // AppShellをレンダリング
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            navigationItems: testNavigationItems,
            previewColumn: const Text('PreviewContent'),
          ),
        ),
      );
      
      // 3つのカラムの主要要素が存在することを確認
      expect(find.text(appTitle), findsOneWidget);
      expect(find.text(editText), findsOneWidget);
      expect(find.text(previewTitleText), findsOneWidget);
    });
    
    testWidgets('タブレットモードで2カラムレイアウトになるか', (WidgetTester tester) async {
      // タブレットサイズを設定
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      
      // AppShellをレンダリング
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            navigationItems: testNavigationItems,
            previewColumn: const Text('PreviewContent'),
          ),
        ),
      );
      
      // プレビューカラムが折りたたまれていることを確認
      expect(find.text(appTitle), findsAtLeastNWidgets(1));
      // タブレットモードでは各カラムの実際のコンテンツが見つかるはず
      expect(find.text('ホームページ'), findsOneWidget);
      
      // プレビュー表示ボタンが表示されているか確認
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
    
    testWidgets('モバイルモードでボトムナビゲーションが表示されるか', (WidgetTester tester) async {
      // モバイルサイズを設定
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      
      // AppShellをレンダリング
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            navigationItems: testNavigationItems,
            previewColumn: const Text('PreviewContent'),
          ),
        ),
      );
      
      // ボトムナビゲーションバーが表示されているか確認
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      
      // メインコンテンツは表示されているか確認
      expect(find.text('ホームページ'), findsOneWidget);
      
      // プレビューボタンが表示されているか確認
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      
      // 音声入力FABが表示されているか確認
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  group('基本画面（ホーム・設定）テスト', () {
    testWidgets('ナビゲーションでページ切り替えができるか', (WidgetTester tester) async {
      // 幅の広いデスクトップサイズを設定
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      
      // AppShellをレンダリング
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            navigationItems: testNavigationItems,
            previewColumn: const Text('PreviewContent'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      // 初期状態ではホームが表示されているか確認
      expect(find.text('ホームページ'), findsOneWidget);
      expect(find.text('設定ページ'), findsNothing);
      
      // 設定ページに切り替え
      final settingFinder = find.widgetWithText(ListTile, '設定');
      expect(settingFinder, findsOneWidget, reason: '設定リストアイテムが見つかりません');
      await tester.tap(settingFinder);
      await tester.pumpAndSettle();
      
      // 設定ページが表示されているか確認
      expect(find.text('ホームページ'), findsNothing);
      expect(find.text('設定ページ'), findsOneWidget);
    });
  });
}
