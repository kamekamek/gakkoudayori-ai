import 'package:flutter_test/flutter_test.dart';
import 'package:yutori_kyoshitu/features/editor/providers/quill_editor_provider.dart';

void main() {
  group('QuillEditorProvider Tests', () {
    late QuillEditorProvider provider;

    setUp(() {
      provider = QuillEditorProvider();
    });

    group('State Management', () {
      test('should have initial state', () {
        expect(provider.isReady, false);
        expect(provider.isLoading, false);
        expect(provider.errorMessage, null);
        expect(provider.content, '');
        expect(provider.plainText, '');
      });

      test('should update ready state', () {
        expect(provider.isReady, false);
        
        provider.setReady(true);
        
        expect(provider.isReady, true);
      });

      test('should update loading state', () {
        expect(provider.isLoading, false);
        
        provider.setLoading(true);
        
        expect(provider.isLoading, true);
      });

      test('should update error message', () {
        expect(provider.errorMessage, null);
        
        provider.setError('Test error');
        
        expect(provider.errorMessage, 'Test error');
      });

      test('should clear error message', () {
        provider.setError('Test error');
        expect(provider.errorMessage, 'Test error');
        
        provider.clearError();
        
        expect(provider.errorMessage, null);
      });

      test('should update content', () {
        expect(provider.content, '');
        
        provider.updateContent('<p>Test content</p>');
        
        expect(provider.content, '<p>Test content</p>');
      });
    });

    group('Document Operations', () {
      test('should save document', () async {
        provider.updateContent('<p>Test content</p>');
        
        final result = await provider.saveDocument('test-document');
        
        expect(result, true);
      });

      test('should load document', () async {
        // First save a document
        provider.updateContent('<p>Test content</p>');
        await provider.saveDocument('test-document');
        
        // Clear current content
        provider.updateContent('');
        
        // Load the document
        final result = await provider.loadDocument('test-document');
        
        expect(result, true);
        expect(provider.content, '<p>Test content</p>');
      });

      test('should handle save error', () async {
        provider.updateContent('<p>Test content</p>');
        
        // Simulate error by using invalid document ID
        final result = await provider.saveDocument('');
        
        expect(result, false);
        expect(provider.errorMessage, isNotNull);
      });

      test('should handle load error', () async {
        // Try to load non-existent document
        final result = await provider.loadDocument('non-existent');
        
        expect(result, false);
        expect(provider.errorMessage, isNotNull);
      });
    });

    group('Theme Management', () {
      test('should have default theme', () {
        expect(provider.currentTheme, 'default');
      });

      test('should change theme', () {
        expect(provider.currentTheme, 'default');
        
        provider.changeTheme('spring');
        
        expect(provider.currentTheme, 'spring');
      });

      test('should validate theme names', () {
        const validThemes = ['default', 'spring', 'summer', 'autumn', 'winter'];
        
        for (final theme in validThemes) {
          provider.changeTheme(theme);
          expect(provider.currentTheme, theme);
        }
      });

      test('should reject invalid theme names', () {
        provider.changeTheme('invalid-theme');
        expect(provider.currentTheme, 'default'); // Should stay default
      });
    });

    group('Content History', () {
      test('should track content changes', () {
        expect(provider.hasUnsavedChanges, false);
        
        provider.updateContent('<p>New content</p>');
        
        expect(provider.hasUnsavedChanges, true);
      });

      test('should clear unsaved changes after save', () async {
        provider.updateContent('<p>New content</p>');
        expect(provider.hasUnsavedChanges, true);
        
        await provider.saveDocument('test-doc');
        
        expect(provider.hasUnsavedChanges, false);
      });

      test('should support undo operation', () {
        provider.updateContent('<p>First</p>');
        provider.updateContent('<p>Second</p>');
        
        expect(provider.canUndo, true);
        
        provider.undo();
        
        expect(provider.content, '<p>First</p>');
      });

      test('should support redo operation', () {
        provider.updateContent('<p>First</p>');
        provider.updateContent('<p>Second</p>');
        provider.undo();
        
        expect(provider.canRedo, true);
        
        provider.redo();
        
        expect(provider.content, '<p>Second</p>');
      });

      test('should limit history size', () {
        // Add more than max history entries
        for (int i = 0; i < 25; i++) {
          provider.updateContent('<p>Content $i</p>');
        }
        
        // Should not have more than max entries
        expect(provider.historySize <= 20, true);
      });
    });

    group('Statistics', () {
      test('should calculate word count', () {
        provider.updateContent('<p>Hello world, this is a test.</p>');
        
        expect(provider.wordCount, 6);
      });

      test('should calculate character count', () {
        provider.updateContent('<p>Hello</p>');
        
        expect(provider.characterCount, 5);
      });

      test('should handle empty content', () {
        provider.updateContent('');
        
        expect(provider.wordCount, 0);
        expect(provider.characterCount, 0);
      });
    });

    group('Editor State Synchronization', () {
      test('should sync with editor state', () async {
        // Simulate editor ready
        provider.setReady(true);
        
        // Update content from editor
        provider.onEditorContentChanged('<p>Updated from editor</p>');
        
        expect(provider.content, '<p>Updated from editor</p>');
      });

      test('should handle editor selection changes', () {
        provider.onEditorSelectionChanged({'index': 5, 'length': 3});
        
        expect(provider.currentSelection['index'], 5);
        expect(provider.currentSelection['length'], 3);
      });
    });
  });
}