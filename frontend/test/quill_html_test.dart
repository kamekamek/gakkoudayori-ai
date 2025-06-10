import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:html/parser.dart' show parse;

void main() {
  group('Quill HTML File Tests', () {
    late String htmlContent;
    
    setUpAll(() async {
      // HTMLファイルを読み込み
      final file = File('web/quill/index.html');
      expect(file.existsSync(), true, reason: 'Quill HTML file should exist');
      htmlContent = await file.readAsString();
    });
    
    test('HTML file should have basic structure', () {
      expect(htmlContent.contains('<!DOCTYPE html>'), true);
      expect(htmlContent.contains('<html lang="ja">'), true);
      expect(htmlContent.contains('<head>'), true);
      expect(htmlContent.contains('<body>'), true);
    });
    
    test('HTML file should include Quill.js CDN links', () {
      expect(htmlContent.contains('cdn.quilljs.com'), true);
      expect(htmlContent.contains('quill.snow.css'), true);
      expect(htmlContent.contains('quill.min.js'), true);
    });
    
    test('HTML file should have Japanese metadata', () {
      expect(htmlContent.contains('charset="UTF-8"'), true);
      expect(htmlContent.contains('lang="ja"'), true);
      expect(htmlContent.contains('ゆとり職員室'), true);
    });
    
    test('HTML file should have custom toolbar configuration', () {
      expect(htmlContent.contains('id="toolbar"'), true);
      expect(htmlContent.contains('ql-header'), true);
      expect(htmlContent.contains('ql-bold'), true);
      expect(htmlContent.contains('ql-color'), true);
      expect(htmlContent.contains('ql-list'), true);
    });
    
    test('HTML file should have editor container', () {
      expect(htmlContent.contains('id="editor"'), true);
      expect(htmlContent.contains('editor-container'), true);
    });
    
    test('HTML file should have JavaScript bridge functions', () {
      expect(htmlContent.contains('window.quillBridge'), true);
      expect(htmlContent.contains('getHTML'), true);
      expect(htmlContent.contains('setHTML'), true);
      expect(htmlContent.contains('getDelta'), true);
      expect(htmlContent.contains('setDelta'), true);
      expect(htmlContent.contains('getText'), true);
      expect(htmlContent.contains('insertText'), true);
    });
    
    test('HTML file should have theme switching functionality', () {
      expect(htmlContent.contains('setTheme'), true);
      expect(htmlContent.contains('spring-theme'), true);
      expect(htmlContent.contains('summer-theme'), true);
      expect(htmlContent.contains('autumn-theme'), true);
      expect(htmlContent.contains('winter-theme'), true);
    });
    
    test('HTML file should have Flutter communication handlers', () {
      expect(htmlContent.contains('flutter_inappwebview'), true);
      expect(htmlContent.contains('onQuillReady'), true);
      expect(htmlContent.contains('onContentChange'), true);
      expect(htmlContent.contains('onSelectionChange'), true);
    });
    
    test('HTML file should be valid HTML', () {
      final document = parse(htmlContent);
      expect(document.documentElement, isNotNull);
      expect(document.head, isNotNull);
      expect(document.body, isNotNull);
    });
    
    test('HTML file should have Japanese content examples', () {
      expect(htmlContent.contains('学級通信'), true);
      expect(htmlContent.contains('今日の学習内容'), true);
      expect(htmlContent.contains('国語：物語の読解'), true);
      expect(htmlContent.contains('算数：分数の計算'), true);
      expect(htmlContent.contains('理科：植物の観察'), true);
    });
    
    test('HTML file should have CSS styling for education theme', () {
      expect(htmlContent.contains('custom-toolbar'), true);
      expect(htmlContent.contains('ql-editor'), true);
      expect(htmlContent.contains('blockquote'), true);
      expect(htmlContent.contains('linear-gradient'), true);
    });
  });
}