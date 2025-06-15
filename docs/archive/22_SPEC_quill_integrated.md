# Quill.js統合仕様書

**カテゴリ**: SPEC | **レイヤー**: DETAIL+IMPL | **更新**: 2025-01-09  
**担当**: 亀ちゃん | **依存**: 20_SPEC_quill_summary.md | **タグ**: #frontend #quill #webview #implementation

## 🎯 TL;DR（30秒で読める要約）

- **目的**: Flutter WebView内のQuill.js WYSIWYGエディタ完全統合
- **対象**: フロントエンド実装者、WebView統合担当者  
- **成果物**: セットアップ→機能→実装の全工程コード
- **次のアクション**: タスク T2-QU-001-A から実装開始

## 🔗 関連ドキュメント

| 種別 | ファイル名 | 関係性 |
|------|-----------|--------|
| 依存 | 20_SPEC_quill_summary.md | 技術概要 |
| 依存 | 10_DESIGN_color_palettes.md | 季節テーマ色定義 |
| 関連 | 23_SPEC_ui_component_design.md | 全体UI設計 |
| 関連 | 30_API_endpoints.md | Delta保存API |

## 📊 メタデータ

- **複雑度**: High
- **推定読了時間**: 15分
- **更新頻度**: 中

---

## Phase 1: 基盤セットアップ

### 1.1 ディレクトリ構造

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
│       └── styles.css                    # カスタムスタイル + 季節テーマ
└── pubspec.yaml
```

### 1.2 HTML基盤

```html
<!-- web/quill/index.html -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Quill Editor</title>
  
  <!-- Quill.js 2.0.0 CDN -->
  <link href="https://cdn.quilljs.com/2.0.0/quill.snow.css" rel="stylesheet">
  <script src="https://cdn.quilljs.com/2.0.0/quill.min.js"></script>
  
  <!-- カスタムスタイル -->
  <link href="styles.css" rel="stylesheet">
</head>
<body>
  <div id="editor-container" class="theme-spring"></div>
  <script src="quill_config.js"></script>
  <script src="flutter_bridge.js"></script>
</body>
</html>
```

### 1.3 基本CSS（季節テーマ統合）

```css
/* web/quill/styles.css */
/* ベーススタイル */
body {
  margin: 0;
  padding: 16px;
  font-family: 'Hiragino Sans', 'Meiryo', sans-serif;
}

#editor-container {
  height: 100%;
  min-height: 400px;
}

.ql-editor {
  font-size: 16px;
  line-height: 1.6;
  font-family: inherit;
}

/* 季節テーマ（10_DESIGN_color_palettes.mdから） */
.theme-spring .ql-editor { background-color: #fff5f5; color: #2d3748; }
.theme-summer .ql-editor { background-color: #f0fff4; color: #1a202c; }
.theme-autumn .ql-editor { background-color: #fffaf0; color: #2d3748; }
.theme-winter .ql-editor { background-color: #f7fafc; color: #1a202c; }

/* ツールバーカスタマイズ */
.ql-toolbar {
  border-top: 1px solid #ccc;
  border-left: 1px solid #ccc;
  border-right: 1px solid #ccc;
}

.ql-container {
  border-left: 1px solid #ccc;
  border-right: 1px solid #ccc;
  border-bottom: 1px solid #ccc;
}
```

### 1.4 依存関係追加

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

## Phase 2: Quill.js機能設計

### 2.1 ツールバー設計（HTML制約準拠）

```javascript
// web/quill/quill_config.js
let quill;

// HTML制約準拠ツールバー
const toolbarOptions = [
  // 見出し（h1, h2, h3のみ）
  [{ 'header': [1, 2, 3, false] }],
  
  // 基本フォーマット（strong, em）
  ['bold', 'italic'],
  
  // リスト（ul, ol, li）
  [{ 'list': 'ordered'}, { 'list': 'bullet' }],
  
  // カスタム機能
  ['ai-assist', 'clean']
];

// Quill エディタ初期化
function initializeQuill() {
  quill = new Quill('#editor-container', {
    theme: 'snow',
    placeholder: '学級通信の内容を入力してください...',
    modules: {
      toolbar: {
        container: toolbarOptions,
        handlers: {
          'ai-assist': showAiAssistHandler
        }
      },
      keyboard: customKeyboard
    }
  });
  
  // コンテンツ変更監視
  quill.on('text-change', function(delta, oldDelta, source) {
    if (source === 'user') {
      notifyFlutter();
    }
  });
  
  console.log('Quill initialized');
  return quill;
}

// HTML制約準拠の出力
function sanitizeQuillHTML(html) {
  const allowedTags = ['h1', 'h2', 'h3', 'p', 'strong', 'em', 'ul', 'ol', 'li', 'br'];
  
  const parser = new DOMParser();
  const doc = parser.parseFromString(html, 'text/html');
  
  // 禁止タグを除去
  doc.querySelectorAll('*').forEach(element => {
    if (!allowedTags.includes(element.tagName.toLowerCase())) {
      element.outerHTML = element.innerHTML;
    }
    // style, class属性を除去
    element.removeAttribute('style');
    element.removeAttribute('class');
  });
  
  return doc.body.innerHTML;
}

// カスタムキーボードショートカット
const customKeyboard = {
  bindings: {
    'ai-assist': {
      key: ' ',
      ctrlKey: true,
      handler: function(range, context) {
        showAiAssistHandler();
        return false;
      }
    },
    'header-1': {
      key: '1',
      ctrlKey: true,
      handler: function(range, context) {
        this.quill.format('header', 1);
        return false;
      }
    }
  }
};

// DOM読み込み完了後に初期化
document.addEventListener('DOMContentLoaded', function() {
  initializeQuill();
});
```

---

## Phase 3: Flutter統合実装

### 3.1 メインWebViewウィジェット

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

### 3.2 JavaScript Bridge サービス

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
      window.quill ? sanitizeQuillHTML(window.quill.root.innerHTML) : null
    ''');
    return result?.toString();
  }

  Future<String?> getDelta() async {
    final result = await controller.evaluateJavascript(source: '''
      window.quill ? JSON.stringify(window.quill.getContents()) : null
    ''');
    return result?.toString();
  }

  Future<void> insertAiContent(String content, int position) async {
    await controller.evaluateJavascript(source: '''
      if (window.quill) {
        window.quill.insertText($position, `$content`);
      }
    ''');
  }

  Future<void> setSeasonTheme(String season) async {
    await controller.evaluateJavascript(source: '''
      const container = document.getElementById('editor-container');
      if (container) {
        container.className = 'theme-$season';
      }
    ''');
  }
}
```

### 3.3 状態管理Provider

```dart
// lib/providers/quill_editor_provider.dart
import 'package:flutter/foundation.dart';
import '../models/quill_delta.dart';
import '../models/editor_state.dart';

class QuillEditorProvider extends ChangeNotifier {
  EditorState _state = EditorState.initial();
  
  EditorState get state => _state;
  bool get isInitialized => _state.isInitialized;
  String get htmlContent => _state.htmlContent;
  String get deltaContent => _state.deltaContent;

  void setInitialized(bool initialized) {
    _state = _state.copyWith(isInitialized: initialized);
    notifyListeners();
  }

  void updateContent(String html, String delta) {
    _state = _state.copyWith(
      htmlContent: html,
      deltaContent: delta,
      lastModified: DateTime.now(),
    );
    notifyListeners();
  }

  void showAiAssist({required String selectedText, required int cursorPosition}) {
    _state = _state.copyWith(
      isAiAssistVisible: true,
      selectedText: selectedText,
      cursorPosition: cursorPosition,
    );
    notifyListeners();
  }

  void hideAiAssist() {
    _state = _state.copyWith(isAiAssistVisible: false);
    notifyListeners();
  }

  void updateSeasonTheme(String season) {
    _state = _state.copyWith(seasonTheme: season);
    notifyListeners();
  }
}
```

### 3.4 データモデル

```dart
// lib/models/editor_state.dart
import 'package:json_annotation/json_annotation.dart';

part 'editor_state.g.dart';

@JsonSerializable()
class EditorState {
  final bool isInitialized;
  final String htmlContent;
  final String deltaContent;
  final DateTime? lastModified;
  final bool isAiAssistVisible;
  final String selectedText;
  final int cursorPosition;
  final String seasonTheme;

  const EditorState({
    required this.isInitialized,
    required this.htmlContent,
    required this.deltaContent,
    this.lastModified,
    required this.isAiAssistVisible,
    required this.selectedText,
    required this.cursorPosition,
    required this.seasonTheme,
  });

  factory EditorState.initial() => const EditorState(
    isInitialized: false,
    htmlContent: '',
    deltaContent: '',
    isAiAssistVisible: false,
    selectedText: '',
    cursorPosition: 0,
    seasonTheme: 'spring',
  );

  EditorState copyWith({
    bool? isInitialized,
    String? htmlContent,
    String? deltaContent,
    DateTime? lastModified,
    bool? isAiAssistVisible,
    String? selectedText,
    int? cursorPosition,
    String? seasonTheme,
  }) {
    return EditorState(
      isInitialized: isInitialized ?? this.isInitialized,
      htmlContent: htmlContent ?? this.htmlContent,
      deltaContent: deltaContent ?? this.deltaContent,
      lastModified: lastModified ?? this.lastModified,
      isAiAssistVisible: isAiAssistVisible ?? this.isAiAssistVisible,
      selectedText: selectedText ?? this.selectedText,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      seasonTheme: seasonTheme ?? this.seasonTheme,
    );
  }

  factory EditorState.fromJson(Map<String, dynamic> json) => 
      _$EditorStateFromJson(json);
  Map<String, dynamic> toJson() => _$EditorStateToJson(this);
}
```

---

## Phase 4: JavaScript Bridge実装

### 4.1 Flutter→JavaScript通信

```javascript
// web/quill/flutter_bridge.js

// AI補助ハンドラー
function showAiAssistHandler() {
  const selection = quill.getSelection();
  const selectedText = selection ? quill.getText(selection.index, selection.length) : '';
  
  window.flutter_inappwebview.callHandler('showAiAssist', {
    selectedText: selectedText,
    cursorPosition: selection ? selection.index : 0
  });
}

// Flutter変更通知
function notifyFlutter() {
  if (window.flutter_inappwebview) {
    const html = sanitizeQuillHTML(quill.root.innerHTML);
    const delta = JSON.stringify(quill.getContents());
    
    window.flutter_inappwebview.callHandler('onContentChange', html, delta);
  }
}

// Flutter からの関数呼び出し対応
window.setQuillContent = function(html) {
  if (quill) {
    quill.root.innerHTML = html;
  }
};

window.getQuillHTML = function() {
  return quill ? sanitizeQuillHTML(quill.root.innerHTML) : '';
};

window.getQuillDelta = function() {
  return quill ? JSON.stringify(quill.getContents()) : '';
};

window.insertAiContent = function(content, position) {
  if (quill) {
    quill.insertText(position, content);
  }
};
```

---

## 🧪 テスト・確認

### 動作確認チェックリスト

#### Phase 1: セットアップ
- [ ] HTMLファイル作成完了
- [ ] CSSスタイル適用完了
- [ ] JavaScript基本動作確認
- [ ] Flutter依存関係追加
- [ ] ローカルテスト通過

#### Phase 2: 機能
- [ ] ツールバーが正常に表示される
- [ ] HTML制約準拠の出力確認
- [ ] キーボードショートカット動作
- [ ] 季節テーマ切り替え確認

#### Phase 3: 統合
- [ ] WebView内でQuill.js表示
- [ ] JavaScript Bridge双方向通信
- [ ] Delta形式での状態管理
- [ ] AI補助ボタン動作確認

### ローカルテスト

```bash
# HTML単体テスト
cd frontend/web/quill
python -m http.server 8000
open http://localhost:8000

# Flutter統合テスト
cd frontend
flutter run -d chrome
```

## ⚠️ 注意事項

1. **HTML制約**: h1,h2,h3,p,strong,em,ul,ol,li,br のみ許可
2. **WebView設定**: Android/iOSでの動作差異に注意
3. **セキュリティ**: JavaScript Bridge設定を慎重に
4. **パフォーマンス**: 大きなHTMLコンテンツでの動作検証
5. **CDN依存**: Quill.js 2.0.0の安定性確認必要 