import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitu/features/editor/services/delta_converter.dart';

void main() {
  group('DeltaConverter Tests', () {
    late DeltaConverter converter;

    setUp(() {
      converter = DeltaConverter();
    });

    group('Delta to HTML Conversion', () {
      test('should convert simple text delta to HTML', () {
        const deltaJson = '''
        {
          "ops": [
            {"insert": "Hello World"}
          ]
        }
        ''';

        final html = converter.deltaToHtml(deltaJson);
        expect(html, contains('Hello World'));
        expect(html, contains('<p>'));
      });

      test('should convert formatted text delta to HTML', () {
        const deltaJson = '''
        {
          "ops": [
            {"insert": "Bold text", "attributes": {"bold": true}},
            {"insert": " and "},
            {"insert": "italic text", "attributes": {"italic": true}}
          ]
        }
        ''';

        final html = converter.deltaToHtml(deltaJson);
        expect(html, contains('<strong>Bold text</strong>'));
        expect(html, contains('<em>italic text</em>'));
      });

      test('should convert headings delta to HTML', () {
        const deltaJson = '''
        {
          "ops": [
            {"insert": "Heading 1"},
            {"insert": "\\n", "attributes": {"header": 1}},
            {"insert": "Heading 2"},
            {"insert": "\\n", "attributes": {"header": 2}}
          ]
        }
        ''';

        final html = converter.deltaToHtml(deltaJson);
        expect(html, contains('<h1>Heading 1</h1>'));
        expect(html, contains('<h2>Heading 2</h2>'));
      });

      test('should convert lists delta to HTML', () {
        const deltaJson = '''
        {
          "ops": [
            {"insert": "Item 1"},
            {"insert": "\\n", "attributes": {"list": "bullet"}},
            {"insert": "Item 2"},
            {"insert": "\\n", "attributes": {"list": "bullet"}}
          ]
        }
        ''';

        final html = converter.deltaToHtml(deltaJson);
        expect(html, contains('<ul>'));
        expect(html, contains('<li>Item 1</li>'));
        expect(html, contains('<li>Item 2</li>'));
      });

      test('should handle empty delta', () {
        const deltaJson = '{"ops": []}';

        final html = converter.deltaToHtml(deltaJson);
        expect(html, isEmpty);
      });

      test('should handle malformed delta JSON', () {
        const invalidJson = 'invalid json';

        expect(() => converter.deltaToHtml(invalidJson), 
          throwsA(isA<FormatException>()));
      });
    });

    group('HTML to Delta Conversion', () {
      test('should convert simple HTML to delta', () {
        const html = '<p>Hello World</p>';

        final deltaJson = converter.htmlToDelta(html);
        final delta = converter.parseDelta(deltaJson);
        
        expect(delta.ops, isNotEmpty);
        expect(delta.ops.first.insert, contains('Hello World'));
      });

      test('should convert formatted HTML to delta', () {
        const html = '<p><strong>Bold</strong> and <em>italic</em></p>';

        final deltaJson = converter.htmlToDelta(html);
        final delta = converter.parseDelta(deltaJson);
        
        expect(delta.ops, hasLength(greaterThan(1)));
        
        // Find bold text operation
        final boldOp = delta.ops.firstWhere(
          (op) => op.insert == 'Bold',
          orElse: () => throw Exception('Bold text not found'),
        );
        expect(boldOp.attributes?['bold'], true);
      });

      test('should convert headings HTML to delta', () {
        const html = '<h1>Title</h1><h2>Subtitle</h2>';

        final deltaJson = converter.htmlToDelta(html);
        final delta = converter.parseDelta(deltaJson);
        
        expect(delta.ops, isNotEmpty);
        
        // Look for header attributes in newline operations
        final headerOps = delta.ops.where(
          (op) => op.insert == '\n' && op.attributes?.containsKey('header') == true
        );
        expect(headerOps, isNotEmpty);
      });

      test('should handle empty HTML', () {
        const html = '';

        final deltaJson = converter.htmlToDelta(html);
        final delta = converter.parseDelta(deltaJson);
        
        expect(delta.ops, isEmpty);
      });
    });

    group('Round-trip Conversion', () {
      test('should maintain content through round-trip conversion', () {
        const originalDelta = '''
        {
          "ops": [
            {"insert": "Hello "},
            {"insert": "World", "attributes": {"bold": true}},
            {"insert": "!"}
          ]
        }
        ''';

        // Delta -> HTML -> Delta
        final html = converter.deltaToHtml(originalDelta);
        final backToDelta = converter.htmlToDelta(html);
        final resultDelta = converter.parseDelta(backToDelta);

        // Should contain the same text content
        final originalText = converter.deltaToPlainText(originalDelta);
        final resultText = converter.deltaToPlainText(backToDelta);
        expect(resultText, equals(originalText));
      });
    });

    group('Utility Methods', () {
      test('should extract plain text from delta', () {
        const deltaJson = '''
        {
          "ops": [
            {"insert": "Hello "},
            {"insert": "World", "attributes": {"bold": true}},
            {"insert": "!"}
          ]
        }
        ''';

        final plainText = converter.deltaToPlainText(deltaJson);
        expect(plainText, equals('Hello World!'));
      });

      test('should validate delta JSON', () {
        const validDelta = '{"ops": [{"insert": "test"}]}';
        const invalidDelta = '{"invalid": "structure"}';

        expect(converter.isValidDelta(validDelta), true);
        expect(converter.isValidDelta(invalidDelta), false);
      });

      test('should sanitize HTML input', () {
        const unsafeHtml = '<script>alert("xss")</script><p>Safe content</p>';

        final deltaJson = converter.htmlToDelta(unsafeHtml);
        final sanitizedHtml = converter.deltaToHtml(deltaJson);
        
        expect(sanitizedHtml, isNot(contains('<script>')));
        expect(sanitizedHtml, contains('Safe content'));
      });
    });
  });
}