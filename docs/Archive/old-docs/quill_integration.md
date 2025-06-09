# Quill.js統合仕様書

## 1. 概要

Flutter WebViewを使ってQuill.jsを統合し、WYSIWYGエディタとして実装します。HTMLのグラレコ風学級通信を編集できるようにします。

## 2. 技術スタック

- **Quill.js**: バージョン 2.0.0、Snow テーマ
- **Flutter**: バージョン 3.32.2
- **WebView**: webview_flutter 4.9.0
- **Bridge**: JavaScript <-> Dart通信

## 3. ディレクトリ構造

```
frontend/
  web/
    quill/
      index.html        # Quill.jsを読み込むHTML
      quill_bridge.js   # Dart<->JS通信ブリッジ
      styles.css        # カスタムスタイル
  lib/
    widgets/
      quill_editor_widget.dart  # WebViewラッパー
    providers/
      quill_editor_provider.dart # 状態管理
    services/
      delta_converter.dart     # Delta<->HTML変換
```

## 4. WebView HTML実装

`frontend/web/quill/index.html`:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Quill Editor</title>
  
  <!-- Quill.js CSS -->
  <link href="https://cdn.quilljs.com/2.0.0/quill.snow.css" rel="stylesheet">
  <link href="styles.css" rel="stylesheet">
  
  <!-- Quill.js Script -->
  <script src="https://cdn.quilljs.com/2.0.0/quill.min.js"></script>
  
  <style>
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
    }
    
    /* 季節テーマ適用 */
    .theme-spring .ql-editor { background-color: #f8f9fa; color: #343a40; }
    .theme-summer .ql-editor { background-color: #f1f8ff; color: #1a1c20; }
    .theme-autumn .ql-editor { background-color: #fff9db; color: #2b2a29; }
    .theme-winter .ql-editor { background-color: #f8f9fa; color: #1a1c20; }
  </style>
</head>
<body>
  <div id="editor-container" class="theme-spring"></div>

  <script>
    // Quill エディタ初期化
    const quill = new Quill('#editor-container', {
      theme: 'snow',
      placeholder: '学級通信の内容を入力してください...',
      modules: {
        toolbar: [
          ['bold', 'italic', 'underline', 'strike'],
          [{ 'header': 1 }, { 'header': 2 }, { 'header': 3 }],
          [{ 'list': 'ordered' }, { 'list': 'bullet' }],
          [{ 'color': [] }, { 'background': [] }],
          ['image', 'link'],
          ['clean']
        ]
      }
    });
    
    // FlutterとのJavaScript通信ブリッジ
    window.addEventListener('flutterInAppWebViewPlatformReady', function(event) {
      // Deltaの取得と設定
      window.flutter_inappwebview.callHandler('getDelta')
        .then(function(delta) {
          if (delta) {
            quill.setContents(JSON.parse(delta));
          }
        });
      
      // 内容変更時のイベント
      quill.on('text-change', function() {
        const delta = JSON.stringify(quill.getContents());
        const html = quill.root.innerHTML;
        window.flutter_inappwebview.callHandler('contentChanged', delta, html);
      });
      
      // テーマ変更メソッド
      window.changeSeason = function(season) {
        const container = document.getElementById('editor-container');
        container.className = '';
        container.classList.add('theme-' + season);
      };
      
      // コンテンツ挿入メソッド
      window.insertContent = function(content, index) {
        if (index === undefined) {
          index = quill.getSelection() ? quill.getSelection().index : 0;
        }
        quill.insertText(index, content);
      };
      
      // HTMLコンテンツ挿入（リッチテキスト）
      window.insertHTML = function(html, index) {
        if (index === undefined) {
          index = quill.getSelection() ? quill.getSelection().index : 0;
        }
        const delta = quill.clipboard.convert(html);
        quill.updateContents(quill.clipboard.convert(html));
      };
      
      // 準備完了通知
      window.flutter_inappwebview.callHandler('editorReady');
    });
  </script>
  
  <script src="quill_bridge.js"></script>
</body>
</html>
```

## 5. Dart側の実装

### QuillEditorWidget

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../providers/quill_editor_provider.dart';

class QuillEditorWidget extends StatefulWidget {
  const QuillEditorWidget({Key? key}) : super(key: key);

  @override
  State<QuillEditorWidget> createState() => _QuillEditorWidgetState();
}

class _QuillEditorWidgetState extends State<QuillEditorWidget> {
  InAppWebViewController? _webViewController;
  bool _isEditorReady = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<QuillEditorProvider>(
      builder: (context, editorProvider, child) {
        return Column(
          children: [
            if (!_isEditorReady)
              const LinearProgressIndicator(),
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: Uri.parse('asset://web/quill/index.html'),
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  _setupJavaScriptHandlers(controller, editorProvider);
                },
                onLoadStop: (controller, url) {
                  debugPrint('Quill Editor loaded');
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _setupJavaScriptHandlers(
    InAppWebViewController controller,
    QuillEditorProvider editorProvider,
  ) {
    // エディタ準備完了通知
    controller.addJavaScriptHandler(
      handlerName: 'editorReady',
      callback: (args) {
        setState(() {
          _isEditorReady = true;
        });
        return null;
      },
    );

    // デルタ取得リクエスト
    controller.addJavaScriptHandler(
      handlerName: 'getDelta',
      callback: (args) {
        return editorProvider.deltaJson;
      },
    );

    // コンテンツ変更通知
    controller.addJavaScriptHandler(
      handlerName: 'contentChanged',
      callback: (args) {
        final delta = args[0] as String;
        final html = args[1] as String;
        editorProvider.updateContent(delta, html);
        return null;
      },
    );
  }

  // 季節テーマ変更
  void changeSeason(String season) {
    if (_webViewController != null && _isEditorReady) {
      _webViewController!.evaluateJavascript(
        source: "window.changeSeason('$season');",
      );
    }
  }

  // テキスト挿入
  void insertText(String text, [int? index]) {
    if (_webViewController != null && _isEditorReady) {
      final indexParam = index != null ? ', $index' : '';
      _webViewController!.evaluateJavascript(
        source: "window.insertContent('$text'$indexParam);",
      );
    }
  }

  // HTML挿入
  void insertHTML(String html, [int? index]) {
    if (_webViewController != null && _isEditorReady) {
      final escapedHtml = html.replaceAll("'", "\\'").replaceAll("\n", "\\n");
      final indexParam = index != null ? ', $index' : '';
      _webViewController!.evaluateJavascript(
        source: "window.insertHTML('$escapedHtml'$indexParam);",
      );
    }
  }
}
```

### QuillEditorProvider

```dart
import 'package:flutter/foundation.dart';

class QuillEditorProvider extends ChangeNotifier {
  String _deltaJson = ''; // Quill Delta JSON
  String _htmlContent = ''; // HTML content
  bool _isLoading = false;
  String? _errorMessage;
  String _currentSeason = 'spring';

  // Getters
  String get deltaJson => _deltaJson;
  String get htmlContent => _htmlContent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentSeason => _currentSeason;

  // コンテンツ更新（エディタからの通知）
  void updateContent(String deltaJson, String htmlContent) {
    _deltaJson = deltaJson;
    _htmlContent = htmlContent;
    notifyListeners();
  }

  // 季節テーマ変更
  void changeSeason(String season) {
    if (['spring', 'summer', 'autumn', 'winter'].contains(season)) {
      _currentSeason = season;
      notifyListeners();
    }
  }

  // ローディング状態設定
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // エラー設定
  void setError(String? error) {
    _errorMessage = error;
    if (error != null) {
      _isLoading = false;
    }
    notifyListeners();
  }

  // デルタとHTMLを直接設定（ロード時など）
  void setContent(String deltaJson, String htmlContent) {
    _deltaJson = deltaJson;
    _htmlContent = htmlContent;
    notifyListeners();
  }

  // エディタリセット
  void resetEditor() {
    _deltaJson = '';
    _htmlContent = '';
    notifyListeners();
  }
}
```

## 6. Delta ⇔ HTML変換

Delta JSONからHTMLへの変換、およびHTMLからDeltaへの変換を行うユーティリティを実装します。これにより、Quill.jsのデータとHTMLの相互変換が可能になります。

Delta形式を直接操作することで、編集状態の完全な保存と復元が可能になります。

### DeltaConverter

```dart
import 'dart:convert';

class DeltaConverter {
  // Delta JSONからクリーンなHTMLに変換
  // div/styleタグを最小限に整理
  static String deltaToCleanHtml(String deltaJson) {
    // 実際の実装はQuill.jsの変換結果をさらに整形
    // 現状はモック実装
    return '<p>変換後のHTMLコンテンツ</p>';
  }
  
  // HTMLからDeltaに変換（近似値）
  static String htmlToDelta(String html) {
    // 実際の実装はQuill.jsのclipboard.convert相当の処理
    // 現状はモック実装
    return '{"ops":[{"insert":"変換後のDeltaコンテンツ\\n"}]}';
  }
  
  // 不要なdiv/styleタグを削除
  static String cleanupHtml(String html) {
    // 実際の実装はHTML整形ロジック
    // 現状はモック実装
    return html.replaceAll(RegExp(r'<div[^>]*>|<\/div>|style="[^"]*"'), '');
  }
}
```

## 7. 保存・読み込み実装

Firestore (メタデータ) と Cloud Storage (delta.json & content.html) の両方に保存する仕組みを実装します。

### DocumentService

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/document.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // ドキュメント保存（Firestoreメタデータ + Storage本文）
  Future<bool> saveDocument(Document document, String deltaJson, String htmlContent) async {
    try {
      // トランザクションで一貫性を保証
      return await _firestore.runTransaction((transaction) async {
        // 1. Firestoreにメタデータ保存
        final docRef = _firestore.collection('letters').doc(document.id);
        transaction.set(docRef, document.toJson());
        
        // 2. Cloud Storageにdelta.jsonとcontent.html保存
        final storageRef = _storage.ref()
            .child('documents')
            .child(document.id);
            
        await storageRef.child('delta.json').putString(
          deltaJson,
          metadata: SettableMetadata(contentType: 'application/json'),
        );
        
        await storageRef.child('content.html').putString(
          htmlContent,
          metadata: SettableMetadata(contentType: 'text/html'),
        );
        
        return true;
      });
    } catch (e) {
      print('Error saving document: $e');
      return false;
    }
  }
  
  // ドキュメント読み込み
  Future<Map<String, dynamic>?> loadDocument(String documentId) async {
    try {
      // 1. Firestoreからメタデータ取得
      final docSnapshot = await _firestore
          .collection('letters')
          .doc(documentId)
          .get();
          
      if (!docSnapshot.exists) {
        return null;
      }
      
      // 2. Cloud Storageからdelta.jsonとcontent.html取得
      final storageRef = _storage.ref()
          .child('documents')
          .child(documentId);
          
      final deltaJson = await storageRef
          .child('delta.json')
          .getData()
          .then((data) => String.fromCharCodes(data!));
          
      final htmlContent = await storageRef
          .child('content.html')
          .getData()
          .then((data) => String.fromCharCodes(data!));
      
      return {
        'document': Document.fromJson(docSnapshot.data()!),
        'deltaJson': deltaJson,
        'htmlContent': htmlContent,
      };
    } catch (e) {
      print('Error loading document: $e');
      return null;
    }
  }
}
```

## 8. AI補助機能との連携

GeminiからのHTMLレスポンスをQuill.jsに挿入するための連携機能を実装します。タグ制約付きプロンプトを使用し、出力されたHTMLを直接エディタに挿入できます。

### AIAssistantService

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIAssistantService {
  final String _baseUrl = 'https://your-backend-api.com/ai';
  
  // HTML制約付きプロンプトでGeminiにテキスト生成リクエスト
  Future<String> generateHtml(String prompt, String customInstruction) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'prompt': prompt,
          'instruction': customInstruction,
          'format': 'html',
          'constraints': {
            'allowedTags': ['h1', 'h2', 'h3', 'p', 'ul', 'ol', 'li', 'strong', 'em', 'br'],
            'disallowedTags': ['style', 'class', 'div'],
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['html'] as String;
      } else {
        throw Exception('Failed to generate HTML: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating HTML: $e');
      throw e;
    }
  }
  
  // リライト機能
  Future<String> rewriteText(String text, String style) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/rewrite'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': text,
          'style': style,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['rewrittenText'] as String;
      } else {
        throw Exception('Failed to rewrite text: ${response.statusCode}');
      }
    } catch (e) {
      print('Error rewriting text: $e');
      throw e;
    }
  }
}
```

## 9. 実装スケジュール

1. **Day 1-2**: WebView + Quill.js基本実装
2. **Day 3-4**: Delta ⇔ HTML変換機能
3. **Day 5-6**: Firestore/Storage連携
4. **Day 7-8**: AI補助UI実装
5. **Day 9-10**: グラレコテンプレート実装
6. **Day 11-12**: テスト・最適化 