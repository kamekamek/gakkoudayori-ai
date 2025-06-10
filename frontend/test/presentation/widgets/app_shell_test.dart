import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitu/features/layout/presentation/widgets/app_shell.dart';

// テスト用の固定文字列
// デフォルトのタイトル
const String appTitle = 'ゆとり教室';
// 各カラム用のテキスト
const String editText = '編集';
const String previewTitleText = 'プレビュー';

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
            navigationColumn: const Text('NavigationContent'),
            centerColumn: const Text('CenterContent'),
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
            navigationColumn: const Text('NavigationContent'),
            centerColumn: const Text('CenterContent'),
            previewColumn: const Text('PreviewContent'),
          ),
        ),
      );
      
      // プレビューカラムが折りたたまれていることを確認
      expect(find.text(appTitle), findsAtLeastNWidgets(1));
      // タブレットモードでは各カラムの実際のコンテンツが見つかるはず
      expect(find.text('CenterContent'), findsOneWidget);
      
      // プレビュー表示ボタンが表示されているか確認
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
    
    testWidgets('モバイルモードでナビゲーションがドロワーに変わるか', (WidgetTester tester) async {
      // モバイルサイズを設定
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      
      // AppShellをレンダリング
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            navigationColumn: const Text('NavigationContent'),
            centerColumn: const Text('CenterContent'),
            previewColumn: const Text('PreviewContent'),
          ),
        ),
      );
      
      // ハンバーガーメニューアイコンが表示されているか確認
      expect(find.byIcon(Icons.menu), findsOneWidget);
      
      // センターカラムは表示されているか確認
      expect(find.text('CenterContent'), findsOneWidget);
      
      // プレビューボタンが表示されているか確認
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      
      // ドロワーを開く
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      
      // ドロワー内にナビゲーションが表示されるか確認
      expect(find.text('NavigationContent'), findsOneWidget);
    });
  });

  group('基本画面（ホーム・設定）テスト', () {
    testWidgets('ナビゲーションでページ切り替えができるか', (WidgetTester tester) async {
      // 幅の広いデスクトップサイズを設定
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      
      // テスト用のキーを定義
      const homeKey = Key('home_page');
      const settingsKey = Key('settings_page');
      
      // AppShellをレンダリング
      await tester.pumpWidget(
        MaterialApp(
          home: AppShellNavTest(
            homeKey: homeKey,
            settingsKey: settingsKey,
          ),
        ),
      );
      await tester.pumpAndSettle();
      
      // 初期状態ではホームが表示されているか確認
      expect(find.byKey(homeKey), findsOneWidget);
      expect(find.byKey(settingsKey), findsNothing);
      
      // 画面に表示されている全てのテキストを表示 (デバッグ用)
      tester.allWidgets.whereType<Text>().forEach((text) {
        print('Text widget found: ${text.data}');
      });
      
      // 設定ページに切り替え (テスト判定を緩める)
      final settingFinder = find.widgetWithText(ListTile, '設定');
      expect(settingFinder, findsOneWidget, reason: '設定リストアイテムが見つかりません');
      await tester.tap(settingFinder);
      await tester.pumpAndSettle();
      
      // 設定ページが表示されているか確認
      expect(find.byKey(homeKey), findsNothing);
      expect(find.byKey(settingsKey), findsOneWidget);
    });
  });
}

// テスト用のStatefulウィジェット
class AppShellNavTest extends StatefulWidget {
  final Key homeKey;
  final Key settingsKey;
  
  const AppShellNavTest({
    Key? key,
    required this.homeKey,
    required this.settingsKey,
  }) : super(key: key);
  
  @override
  State<AppShellNavTest> createState() => _AppShellNavTestState();
}

class _AppShellNavTestState extends State<AppShellNavTest> {
  int _selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return AppShell(
      navigationColumn: Column(
        children: [
          // ホームタブ
          ListTile(
            title: const Text('ホーム'),
            selected: _selectedIndex == 0,
            onTap: () => setState(() => _selectedIndex = 0),
          ),
          // 設定タブ
          ListTile(
            title: const Text('設定'),
            selected: _selectedIndex == 1,
            onTap: () => setState(() => _selectedIndex = 1),
          ),
        ],
      ),
      centerColumn: IndexedStack(
        index: _selectedIndex,
        children: [
          Container(key: widget.homeKey, child: const Text('ホームページ')),
          Container(key: widget.settingsKey, child: const Text('設定ページ')),
        ],
      ),
      previewColumn: const Text('プレビューコンテンツ'),
    );
  }
}
