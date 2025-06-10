import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yutori_kyoshitu/features/ai_assistant/presentation/widgets/ai_assistant_panel.dart';
import 'package:yutori_kyoshitu/features/editor/providers/quill_editor_provider.dart';

void main() {
  group('AIAssistantPanel', () {
    late QuillEditorProvider mockProvider;

    setUp(() {
      mockProvider = QuillEditorProvider();
    });

    testWidgets('should display AI assistant header', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<QuillEditorProvider>(
              create: (_) => mockProvider,
              child: AIAssistantPanel(),
            ),
          ),
        ),
      );

      // AI補助ヘッダーが表示されることを確認
      expect(find.text('AI補助'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('should toggle panel visibility when header is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<QuillEditorProvider>(
              create: (_) => mockProvider,
              child: AIAssistantPanel(),
            ),
          ),
        ),
      );

      // 初期状態では折りたたまれている
      expect(mockProvider.isAiAssistVisible, false);

      // ヘッダーをタップ
      await tester.tap(find.text('AI補助'));
      await tester.pump();

      // パネルが展開される
      expect(mockProvider.isAiAssistVisible, true);

      // 再度タップ
      await tester.tap(find.text('AI補助'));
      await tester.pump();

      // パネルが折りたたまれる
      expect(mockProvider.isAiAssistVisible, false);
    });

    testWidgets('should animate arrow rotation when panel toggles', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<QuillEditorProvider>(
              create: (_) => mockProvider,
              child: AIAssistantPanel(),
            ),
          ),
        ),
      );

      // 初期状態のアニメーション
      final arrowWidget = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      expect(arrowWidget.turns, 0.0);

      // パネル展開
      await tester.tap(find.text('AI補助'));
      await tester.pump();

      final expandedArrowWidget = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      expect(expandedArrowWidget.turns, 0.5);
    });

    testWidgets('should animate panel height when toggling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<QuillEditorProvider>(
              create: (_) => mockProvider,
              child: AIAssistantPanel(),
            ),
          ),
        ),
      );

      // AnimatedContainerが存在することを確認
      expect(find.byType(AnimatedContainer), findsOneWidget);

      // アニメーション設定の確認
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(animatedContainer.duration, Duration(milliseconds: 300));
      expect(animatedContainer.curve, Curves.easeInOut);
    });

    testWidgets('should show panel content when expanded', (WidgetTester tester) async {
      // 事前にパネルを展開状態にセット
      mockProvider.showAiAssist(selectedText: '', cursorPosition: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<QuillEditorProvider>(
              create: (_) => mockProvider,
              child: AIAssistantPanel(),
            ),
          ),
        ),
      );

      await tester.pump();

      // パネルコンテンツが表示されることを確認
      // 注：実際のコンテンツは次のタスクで実装するため、ここではコンテナの存在のみ確認
      expect(find.byKey(Key('ai_panel_content')), findsOneWidget);
    });
  });
}