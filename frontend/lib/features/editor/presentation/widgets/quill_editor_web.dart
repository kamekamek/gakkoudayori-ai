// Web-specific implementation
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class QuillEditorWebImplementation {
  static const String viewType = 'quill-editor-iframe';
  static late html.IFrameElement iframe;
  
  static void registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => iframe,
    );
  }
  
  static html.IFrameElement createIFrame() {
    return html.IFrameElement()
      ..src = 'quill/index.html'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
  }
}