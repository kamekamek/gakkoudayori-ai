# Quill.js Flutter実装詳細書

**カテゴリ**: SPEC | **レイヤー**: IMPL | **更新**: 2025-01-09  
**担当**: 亀ちゃん | **依存**: 22_SPEC_quill_features.md | **タグ**: #flutter #webview #implementation

## 🎯 TL;DR（30秒で読める要約）

- **目的**: Flutter WebViewでQuill.jsを統合する実装手順を詳細化
- **対象**: Flutter開発者、WebView統合担当者  
- **成果物**: JavaScript Bridge、Delta変換、状態管理の実装コード
- **次のアクション**: 実装開始・テスト実行

## 🔗 関連ドキュメント

| 種別 | ファイル名 | 関係性 |
|------|-----------|--------|
| 依存 | 22_SPEC_quill_features.md | Quill機能仕様 |
| 依存 | 21_SPEC_quill_setup.md | 基本セットアップ |
| 関連 | 21_SPEC_ui_component_design.md | UI設計 |

## 📊 メタデータ

- **複雑度**: High
- **推定読了時間**: 10分
- **更新頻度**: 高

---

## 1. プロジェクト構造

### 1.1 ファイル配置

```
frontend/
├── lib/
│   ├── widgets/
│   │   └── quill_editor_widget.dart        # メインWebViewウィジェット
│   ├── providers/
│   │   └── quill_editor_provider.dart      # 状態管理
│   ├── models/
│   │   ├── quill_delta.dart               # Delta データモデル
│   │   └── editor_state.dart              # エディタ状態
│   └── services/
│       └── quill_bridge_service.dart      # JavaScript Bridge
├── web/
│   └── quill/
│       ├── index.html                     # Quillエディタページ
│       ├── quill_config.js               # Quill設定
│       ├── flutter_bridge.js             # Flutter連携
│       └── styles.css                    # カスタムスタイル
└── pubspec.yaml
```

### 1.2 依存関係追加

```yaml
# pubspec.yaml
dependencies:
  flutter_inappwebview: ^6.0.0
  provider: ^6.1.1
  json_annotation: ^4.8.1

dev_dependencies:
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

---

## 2. WebView実装

### 2.1 メインWebViewウィジェット

```dart
// lib/widgets/quill_editor_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../providers/quill_editor_provider.dart';
import '../services/quill_bridge_service.dart';

class QuillEditorWidget extends StatefulWidget {
  final String? initialContent;
  final Function(String html, String delta)? onContentChanged;
  
  const QuillEditorWidget({
    Key? key,
    this.initialContent,
    this.onContentChanged,
  }) : super(key: key);

  @override
  State<QuillEditorWidget> createState() => _QuillEditorWidgetState();
}

class _QuillEditorWidgetState extends State<QuillEditorWidget> {
  InAppWebViewController? webViewController;
  QuillBridgeService? bridgeService;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<QuillEditorProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri.uri(Uri.parse('assets/web/quill/index.html'))
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                allowsInlineMediaPlayback: true,
                mediaPlaybackRequiresUserGesture: false,
                transparentBackground: true,
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
                bridgeService = QuillBridgeService(controller);
                _setupJavaScriptHandlers();
              },
              onLoadStop: (controller, url) async {
                await _initializeQuill();
              },
            ),
          ),
        );
      },
    );
  }

  void _setupJavaScriptHandlers() {
    webViewController!.addJavaScriptHandler(
      handlerName: 'onContentChange',
      callback: (args) {
        final html = args[0] as String;
        final delta = args[1] as String;
        
        context.read<QuillEditorProvider>().updateContent(html, delta);
        widget.onContentChanged?.call(html, delta);
      },
    );

    webViewController!.addJavaScriptHandler(
      handlerName: 'showAiAssist',
      callback: (args) {
        final data = Map<String, dynamic>.from(args[0]);
        context.read<QuillEditorProvider>().showAiAssist(
          selectedText: data['selectedText'] as String,
          cursorPosition: data['cursorPosition'] as int,
        );
      },
    );
  }

  Future<void> _initializeQuill() async {
    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      await bridgeService!.setContent(widget.initialContent!);
    }
    context.read<QuillEditorProvider>().setInitialized(true);
  }
}
```

### 2.2 JavaScript Bridge サービス

```dart
// lib/services/quill_bridge_service.dart
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class QuillBridgeService {
  final InAppWebViewController controller;

  QuillBridgeService(this.controller);

  Future<void> setContent(String html) async {
    await controller.evaluateJavascript(source: '''
      if (window.quill) {
        window.quill.root.innerHTML = `$html`;
      }
    ''');
  }

  Future<String?> getHTML() async {
    final result = await controller.evaluateJavascript(source: '''
      window.quill ? window.quill.root.innerHTML : null
    ''');
    return result?.toString();
  }

  Future<void> insertAiContent(String content, int position) async {
    await controller.evaluateJavascript(source: '''
      if (window.quill && window.quillAiAssistant) {
        window.quillAiAssistant.insertAiContent(`$content`, $position);
      }
    ''');
  }
}
```

---

## 3. 状態管理実装

### 3.1 QuillEditorProvider

```dart
// lib/providers/quill_editor_provider.dart
import 'package:flutter/material.dart';

class QuillEditorProvider extends ChangeNotifier {
  String _htmlContent = '';
  String _deltaJson = '{"ops":[]}';
  bool _isInitialized = false;
  bool _isAiAssistVisible = false;
  String _selectedText = '';
  int _cursorPosition = 0;

  String get htmlContent => _htmlContent;
  String get deltaJson => _deltaJson;
  bool get isInitialized => _isInitialized;
  bool get isAiAssistVisible => _isAiAssistVisible;

  void setInitialized(bool initialized) {
    _isInitialized = initialized;
    notifyListeners();
  }

  void updateContent(String html, String delta) {
    _htmlContent = html;
    _deltaJson = delta;
    notifyListeners();
  }

  void showAiAssist({
    required String selectedText,
    required int cursorPosition,
  }) {
    _selectedText = selectedText;
    _cursorPosition = cursorPosition;
    _isAiAssistVisible = true;
    notifyListeners();
  }

  void hideAiAssist() {
    _isAiAssistVisible = false;
    notifyListeners();
  }
}
```

---

## 4. JavaScript実装

### 4.1 HTML基盤

```html
<!-- web/quill/index.html -->
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quill Editor</title>
    
    <link href="https://cdn.quilljs.com/2.0.0/quill.snow.css" rel="stylesheet">
    <script src="https://cdn.quilljs.com/2.0.0/quill.min.js"></script>
    
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <div id="toolbar"></div>
    <div id="editor"></div>
    
    <script src="quill_config.js"></script>
    <script src="flutter_bridge.js"></script>
</body>
</html>
```

### 4.2 Quill設定

```javascript
// web/quill/quill_config.js
let quill;

function initializeQuill() {
  const toolbarOptions = [
    [{ 'header': [1, 2, 3, false] }],
    ['bold', 'italic'],
    [{ 'list': 'ordered'}, { 'list': 'bullet' }],
    ['ai-assist']
  ];

  quill = new Quill('#editor', {
    theme: 'snow',
    modules: {
      toolbar: {
        container: toolbarOptions,
        handlers: {
          'ai-assist': showAiAssistPanel
        }
      }
    },
    formats: ['header', 'bold', 'italic', 'list'],
    placeholder: 'ここに学級通信の内容を入力してください...'
  });

  quill.on('text-change', handleTextChange);
}

function handleTextChange(delta, oldDelta, source) {
  if (source === 'user') {
    const html = quill.root.innerHTML;
    const deltaJson = JSON.stringify(quill.getContents());
    
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('onContentChange', html, deltaJson);
    }
  }
}

function showAiAssistPanel() {
  const range = quill.getSelection();
  if (range && window.flutter_inappwebview) {
    const selectedText = quill.getText(range.index, range.length);
    
    window.flutter_inappwebview.callHandler('showAiAssist', {
      selectedText: selectedText,
      cursorPosition: range.index
    });
  }
}

document.addEventListener('DOMContentLoaded', initializeQuill);
```

### 4.3 Flutter Bridge

```javascript
// web/quill/flutter_bridge.js
window.setQuillContent = function(html) {
  if (quill) {
    quill.root.innerHTML = html;
  }
};

window.getQuillHTML = function() {
  return quill ? quill.root.innerHTML : '';
};

window.insertAiContent = function(content, position) {
  if (quill) {
    quill.insertText(position, content);
    quill.setSelection(position + content.length);
  }
};
```

---

## 5. 使用例

```dart
// 使用例
class EditorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuillEditorProvider(),
      child: Scaffold(
        appBar: AppBar(title: Text('学級通信エディタ')),
        body: Column(
          children: [
            Expanded(
              child: QuillEditorWidget(
                initialContent: '<h1>学級通信</h1><p>内容をここに入力...</p>',
                onContentChanged: (html, delta) {
                  print('Content changed: $html');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

この実装により、Flutter WebViewとQuill.jsが統合され、要件書で求められるWYSIWYGエディタが実現できます。 