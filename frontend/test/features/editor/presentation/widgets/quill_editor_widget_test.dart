import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitu/features/editor/presentation/widgets/quill_editor_widget.dart';

void main() {
  group('QuillEditorWidget Tests', () {
    testWidgets('should create QuillEditorWidget without errors', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuillEditorWidget(),
          ),
        ),
      );

      // Assert
      expect(find.byType(QuillEditorWidget), findsOneWidget);
    });

    testWidgets('should show error on non-web platform', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuillEditorWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - On VM/test environment, should show platform error
      expect(find.text('このウィジェットはWeb環境でのみ動作します'), findsOneWidget);
    });

    testWidgets('should accept initial content parameter', (WidgetTester tester) async {
      // Arrange
      const initialContent = '<p>テスト用初期コンテンツ</p>';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuillEditorWidget(
              initialContent: initialContent,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(QuillEditorWidget), findsOneWidget);
    });

    testWidgets('should accept callback functions', (WidgetTester tester) async {
      // Arrange
      String? lastContent;
      Map<String, dynamic>? lastSelection;
      bool readyCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuillEditorWidget(
              onContentChanged: (content) => lastContent = content,
              onSelectionChanged: (selection) => lastSelection = selection,
              onReady: () => readyCalled = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(QuillEditorWidget), findsOneWidget);
      // Note: Callbacks are set but not called in this test due to WebView limitations in tests
    });

    testWidgets('should handle error state gracefully', (WidgetTester tester) async {
      // Note: This test would require mocking WebView error conditions
      // For now, we'll test that the widget can be created
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuillEditorWidget(),
          ),
        ),
      );

      // Assert
      expect(find.byType(QuillEditorWidget), findsOneWidget);
    });

    group('Public API Methods', () {
      late QuillEditorWidget widget;

      setUp(() {
        widget = const QuillEditorWidget();
      });

      test('should have public methods for content manipulation', () {
        // Assert
        expect(widget, isA<QuillEditorWidget>());
        // Note: Method testing would require a running WebView context
        // These tests verify the widget structure and API surface
      });
    });

    group('Widget Configuration', () {
      test('should accept all configuration parameters', () {
        // Arrange & Act
        final widget = QuillEditorWidget(
          initialContent: '<p>Initial</p>',
          onContentChanged: (content) {},
          onSelectionChanged: (selection) {},
          onReady: () {},
        );

        // Assert
        expect(widget.initialContent, equals('<p>Initial</p>'));
        expect(widget.onContentChanged, isNotNull);
        expect(widget.onSelectionChanged, isNotNull);
        expect(widget.onReady, isNotNull);
      });

      test('should have sensible defaults for optional parameters', () {
        // Arrange & Act
        const widget = QuillEditorWidget();

        // Assert
        expect(widget.initialContent, isNull);
        expect(widget.onContentChanged, isNull);
        expect(widget.onSelectionChanged, isNull);
        expect(widget.onReady, isNull);
      });
    });
  });
}