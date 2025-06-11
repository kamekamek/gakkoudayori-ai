import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitu/features/editor/providers/quill_editor_provider.dart';
import 'package:yutori_kyoshitu/features/editor/services/javascript_bridge.dart';
import 'package:yutori_kyoshitu/features/editor/services/delta_converter.dart';

void main() {
  group('Quill Integration Tests', () {
    late QuillEditorProvider provider;
    late JavaScriptBridge bridge;
    late DeltaConverter converter;

    setUp(() {
      provider = QuillEditorProvider();
      bridge = JavaScriptBridge();
      converter = DeltaConverter();
    });

    test('should integrate all Quill components', () {
      // Test provider initialization
      expect(provider.isReady, false);
      expect(provider.content, '');

      // Test bridge command creation
      final command = QuillCommands.getHTML();
      expect(command.method, 'getHTML');
      
      final serialized = bridge.serializeCommand(command);
      expect(serialized, contains('getHTML'));

      // Test content management
      provider.updateContent('<p>Test content</p>');
      expect(provider.content, '<p>Test content</p>');
      expect(provider.hasUnsavedChanges, true);

      // Test theme management
      provider.changeTheme('spring');
      expect(provider.currentTheme, 'spring');

      // Test statistics
      expect(provider.wordCount, 2); // "Test content"
      expect(provider.characterCount, 12); // "Test content"
    });

    test('should handle delta conversion workflow', () {
      // Create simple delta
      const deltaJson = '''
      {
        "ops": [
          {"insert": "Hello World"}
        ]
      }
      ''';

      // Convert to HTML
      final html = converter.deltaToHtml(deltaJson);
      expect(html, contains('Hello World'));

      // Update provider with converted content
      provider.updateContent(html);
      expect(provider.content, html);
      expect(provider.plainText, contains('Hello World'));
    });

    test('should manage complete document lifecycle', () async {
      // Create new document
      provider.createNewDocument();
      expect(provider.content, '');
      expect(provider.hasUnsavedChanges, false);

      // Add content
      provider.updateContent('<h1>My Document</h1><p>This is content.</p>');
      expect(provider.hasUnsavedChanges, true);
      expect(provider.wordCount, 4); // "My Document This is content"

      // Save document
      final saveResult = await provider.saveDocument('test-doc-1');
      expect(saveResult, true);
      expect(provider.hasUnsavedChanges, false);

      // Create another document
      provider.createNewDocument();
      provider.updateContent('<p>Different content</p>');

      // Load the first document
      final loadResult = await provider.loadDocument('test-doc-1');
      expect(loadResult, true);
      expect(provider.content, '<h1>My Document</h1><p>This is content.</p>');
    });

    test('should handle error scenarios gracefully', () async {
      // Test invalid document save
      final result = await provider.saveDocument('');
      expect(result, false);
      expect(provider.errorMessage, isNotNull);

      // Clear error
      provider.clearError();
      expect(provider.errorMessage, null);

      // Test invalid theme
      provider.changeTheme('invalid-theme');
      expect(provider.currentTheme, 'default');
    });

    test('should provide comprehensive editor state', () {
      // Set up editor state
      provider.setReady(true);
      provider.updateContent('<p>Sample content for statistics</p>');
      provider.changeTheme('autumn');

      // Get statistics
      final stats = provider.getStatistics();
      expect(stats.wordCount, 4); // "Sample content for statistics"
      expect(stats.currentTheme, 'autumn');
      expect(stats.hasUnsavedChanges, true);
      expect(stats.lineCount, 1);
    });

    group('Bridge Command Integration', () {
      test('should create correct commands for all operations', () {
        final commands = [
          QuillCommands.getHTML(),
          QuillCommands.setHTML('<p>test</p>'),
          QuillCommands.getDelta(),
          QuillCommands.getText(),
          QuillCommands.insertText('Hello'),
          QuillCommands.focus(),
          QuillCommands.setTheme('spring'),
          QuillCommands.ping(),
        ];

        for (final command in commands) {
          expect(command.method, isNotEmpty);
          expect(command.id, isNotEmpty);
          
          final serialized = bridge.serializeCommand(command);
          expect(serialized, contains(command.method));
        }
      });

      test('should handle command responses', () {
        // Success response
        const successJson = '{"success": true, "data": "<p>test</p>"}';
        final successResponse = bridge.deserializeResponse(successJson);
        expect(successResponse.success, true);
        expect(successResponse.data, '<p>test</p>');

        // Error response
        const errorJson = '{"success": false, "error": "Test error"}';
        final errorResponse = bridge.deserializeResponse(errorJson);
        expect(errorResponse.success, false);
        expect(errorResponse.error, 'Test error');
      });
    });
  });
}