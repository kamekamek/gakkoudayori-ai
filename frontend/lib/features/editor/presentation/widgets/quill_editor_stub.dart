// Stub implementation for non-web platforms
class QuillEditorWebImplementation {
  static const String viewType = 'quill-editor-iframe';
  static dynamic iframe;
  
  static void registerViewFactory() {
    throw UnsupportedError('Web-only feature');
  }
  
  static dynamic createIFrame() {
    throw UnsupportedError('Web-only feature');
  }
}