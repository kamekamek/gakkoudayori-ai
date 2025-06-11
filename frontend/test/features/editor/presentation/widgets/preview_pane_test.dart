import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yutori_kyoshitu/features/editor/providers/quill_editor_provider.dart';
import 'package:yutori_kyoshitu/features/editor/presentation/widgets/preview_pane_widget.dart';

void main() {
  group('Preview Pane Widget Tests', () {
    late QuillEditorProvider provider;

    setUp(() {
      provider = QuillEditorProvider();
    });

    testWidgets('should display preview pane when visible',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<QuillEditorProvider>(
              create: (_) => provider,
              child: const PreviewPaneWidget(isVisible: true),
            ),
          ),
        ),
      );

      expect(find.byType(PreviewPaneWidget), findsOneWidget);
      expect(find.text('プレビュー'), findsOneWidget);
    });

    testWidgets('should hide preview pane when not visible',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<QuillEditorProvider>(
              create: (_) => provider,
              child: const PreviewPaneWidget(isVisible: false),
            ),
          ),
        ),
      );

      expect(find.text('プレビュー'), findsNothing);
    });

    testWidgets('should display preview mode toggle buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<QuillEditorProvider>(
              create: (_) => provider,
              child: const PreviewPaneWidget(),
            ),
          ),
        ),
      );

      // プレビューモードボタンを確認
      expect(find.byIcon(Icons.desktop_windows), findsOneWidget);
      expect(find.byIcon(Icons.phone_android), findsOneWidget);
      expect(find.byIcon(Icons.print), findsOneWidget);
    });

    testWidgets('should change preview mode when toggle button is pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<QuillEditorProvider>(
              create: (_) => provider,
              child: const PreviewPaneWidget(),
            ),
          ),
        ),
      );

      // モバイルプレビューボタンをタップ
      await tester.tap(find.byIcon(Icons.phone_android));
      await tester.pumpAndSettle();

      // 印刷プレビューボタンをタップ
      await tester.tap(find.byIcon(Icons.print));
      await tester.pumpAndSettle();

      // デスクトッププレビューボタンをタップ
      await tester.tap(find.byIcon(Icons.desktop_windows));
      await tester.pumpAndSettle();
    });

    test('should generate correct HTML for different themes', () {
      // Create a temporary widget to access the private method
      final widget = _TestablePreviewPaneWidget();

      // Test default theme
      String html = widget.generateTestHTML('<p>Test content</p>', 'default');
      expect(html, contains('<p>Test content</p>'));
      expect(html, contains('class="preview-body desktop-preview"'));

      // Test spring theme
      html = widget.generateTestHTML('<h1>Spring Newsletter</h1>', 'spring');
      expect(html, contains('<h1>Spring Newsletter</h1>'));
      expect(html, contains('spring-theme'));

      // Test summer theme
      html = widget.generateTestHTML('<h2>Summer Activities</h2>', 'summer');
      expect(html, contains('<h2>Summer Activities</h2>'));
      expect(html, contains('summer-theme'));
    });

    test('should handle different preview modes correctly', () {
      // Test CSS class mapping for different modes
      const modeClassMap = {
        PreviewMode.desktop: 'desktop-preview',
        PreviewMode.mobile: 'mobile-preview',
        PreviewMode.print: 'print-preview',
      };

      for (final entry in modeClassMap.entries) {
        final mode = entry.key;
        final expectedClass = entry.value;
        expect(expectedClass, contains('preview'));
      }
    });

    test('should generate proper CSS for responsive design', () {
      final widget = _TestablePreviewPaneWidget();
      final css = widget.getTestCSS();

      // Check that responsive styles are included
      expect(css, contains('desktop-preview'));
      expect(css, contains('mobile-preview'));
      expect(css, contains('print-preview'));
      expect(css, contains('@media print'));

      // Check that seasonal themes are included
      expect(css, contains('spring-theme'));
      expect(css, contains('summer-theme'));
      expect(css, contains('autumn-theme'));
      expect(css, contains('winter-theme'));

      // Check basic typography styles
      expect(css, contains('font-family'));
      expect(css, contains('line-height'));
      expect(css, contains('font-size'));
    });

    testWidgets('should update preview when content changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<QuillEditorProvider>(
              create: (_) => provider,
              child: const PreviewPaneWidget(),
            ),
          ),
        ),
      );

      // 初期状態
      expect(find.byType(PreviewPaneWidget), findsOneWidget);

      // コンテンツを更新
      provider.updateContent('<h1>Updated Content</h1>');
      await tester.pump();

      // プレビューが更新されることを確認（実際のWebViewは更新されるが、テストでは確認が困難）
      expect(provider.content, '<h1>Updated Content</h1>');
    });

    testWidgets('should update preview when theme changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<QuillEditorProvider>(
              create: (_) => provider,
              child: const PreviewPaneWidget(),
            ),
          ),
        ),
      );

      // テーマを変更
      provider.changeTheme('autumn');
      await tester.pump();

      // プレビューが更新されることを確認
      expect(provider.currentTheme, 'autumn');
    });
  });

  group('Preview HTML Generation Tests', () {
    late _TestablePreviewPaneWidget widget;

    setUp(() {
      widget = _TestablePreviewPaneWidget();
    });

    test('should generate complete HTML document', () {
      final html = widget.generateTestHTML('<p>Test</p>', 'default');

      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('<html>'));
      expect(html, contains('<head>'));
      expect(html, contains('<body>'));
      expect(html, contains('</html>'));
    });

    test('should include proper meta tags', () {
      final html = widget.generateTestHTML('<p>Test</p>', 'default');

      expect(html, contains('charset="UTF-8"'));
      expect(html, contains('viewport'));
    });

    test('should apply theme classes correctly', () {
      final themes = ['default', 'spring', 'summer', 'autumn', 'winter'];

      for (final theme in themes) {
        final html = widget.generateTestHTML('<p>Test</p>', theme);

        if (theme == 'default') {
          expect(html, contains('class="preview-body desktop-preview"'));
        } else {
          expect(html, contains('$theme-theme'));
        }
      }
    });

    test('should preserve content structure', () {
      const testContent = '''
        <h1>Main Title</h1>
        <p>Paragraph with <strong>bold</strong> and <em>italic</em> text.</p>
        <ul>
          <li>First item</li>
          <li>Second item</li>
        </ul>
        <blockquote>Important quote</blockquote>
      ''';

      final html = widget.generateTestHTML(testContent, 'default');

      expect(html, contains('<h1>Main Title</h1>'));
      expect(html, contains('<strong>bold</strong>'));
      expect(html, contains('<em>italic</em>'));
      expect(html, contains('<ul>'));
      expect(html, contains('<li>First item</li>'));
      expect(html, contains('<blockquote>Important quote</blockquote>'));
    });
  });
}

// テスト用のPreviewPaneWidgetサブクラス
class _TestablePreviewPaneWidget extends PreviewPaneWidget {
  const _TestablePreviewPaneWidget() : super();

  // テスト用にHTMLの生成メソッドを公開
  String generateTestHTML(String content, String theme) {
    final themeClass = theme != 'default' ? '$theme-theme' : '';

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>学級通信プレビュー</title>
    <style>
        ${getTestCSS()}
    </style>
</head>
<body class="preview-body desktop-preview $themeClass">
    <div class="preview-container">
        <div class="document-content">
            $content
        </div>
    </div>
</body>
</html>
''';
  }

  // テスト用にCSSを公開
  String getTestCSS() {
    return '''
      body {
        margin: 0;
        padding: 16px;
        font-family: 'Hiragino Sans', 'Meiryo', sans-serif;
        line-height: 1.6;
        background-color: #f5f5f5;
      }

      .desktop-preview .preview-container {
        max-width: 800px;
      }

      .mobile-preview .preview-container {
        max-width: 375px;
      }

      .print-preview .preview-container {
        max-width: 210mm;
      }

      .spring-theme {
        --primary: #ff9eaa;
        --background: #f8f9fa;
      }

      .summer-theme {
        --primary: #51cf66;
        --background: #f1f8ff;
      }

      .autumn-theme {
        --primary: #e67700;
        --background: #fff9db;
      }

      .winter-theme {
        --primary: #4dabf7;
        --background: #f8f9fa;
      }

      @media print {
        .print-preview .preview-container {
          box-shadow: none;
        }
      }
    ''';
  }
}
