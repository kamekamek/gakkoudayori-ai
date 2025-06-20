# エディタ機能ガイド

学校だよりAIのWYSIWYGエディタ機能について、Quill.jsの統合から高度な編集機能まで詳しく解説します。

## 🎯 エディタ概要

学校だよりAIは、Quill.jsをベースにしたリッチテキストエディタを提供しています。教師が直感的に文書を編集できるよう、多くのカスタマイズを加えています。

### 主な特徴

- 📝 **WYSIWYG編集**: 見たまま編集が可能
- 🖼️ **画像管理**: ドラッグ&ドロップで簡単挿入
- 🎨 **テンプレート**: 季節や行事に応じたデザイン
- 📱 **レスポンシブ**: PC・タブレット・スマホ対応
- 💾 **自動保存**: 編集内容を自動的に保存

## 🛠️ Quill.js統合アーキテクチャ

### システム構成

```
Flutter Web App
    ↓
WebView (HtmlElementView)
    ↓
web/quill/index.html (Quill.js実装)
    ↓
JavaScript Bridge
    ↓
QuillEditorProvider (状態管理)
```

### JavaScript Bridge実装

```dart
// lib/features/editor/services/javascript_bridge.dart
class JavaScriptBridge {
  static void initializeBridge() {
    // Flutter → JavaScript
    window.postMessage({
      'type': 'flutter-to-js',
      'action': 'initialize',
      'data': {}
    }, '*');
    
    // JavaScript → Flutter
    window.addEventListener('message', (event) {
      final data = event.data;
      if (data['type'] == 'js-to-flutter') {
        _handleJavaScriptMessage(data);
      }
    });
  }
}
```

### Quill.js初期化

```javascript
// web/quill/index.html
const quill = new Quill('#editor', {
  theme: 'snow',
  modules: {
    toolbar: {
      container: [
        [{ 'header': [1, 2, 3, false] }],
        ['bold', 'italic', 'underline', 'strike'],
        [{ 'color': [] }, { 'background': [] }],
        [{ 'list': 'ordered'}, { 'list': 'bullet' }],
        ['blockquote', 'code-block'],
        ['link', 'image', 'video'],
        ['clean']
      ],
      handlers: {
        image: imageHandler // カスタムハンドラー
      }
    },
    imageResize: {
      displaySize: true
    },
    clipboard: {
      matchVisual: false
    }
  }
});
```

## 📝 基本的な編集機能

### テキスト装飾

```javascript
// 太字の適用
function applyBold() {
  const range = quill.getSelection();
  if (range) {
    quill.formatText(range.index, range.length, 'bold', true);
  }
}

// 見出しの設定
function setHeading(level) {
  quill.format('header', level);
}

// 色の変更
function changeColor(color) {
  quill.format('color', color);
}
```

### リスト機能

```javascript
// 番号付きリスト
quill.format('list', 'ordered');

// 箇条書きリスト
quill.format('list', 'bullet');

// インデント調整
quill.format('indent', '+1'); // インデント増
quill.format('indent', '-1'); // インデント減
```

## 🖼️ 画像処理機能

### 画像アップロード実装

```dart
// lib/features/editor/services/image_upload_service.dart
class ImageUploadService {
  Future<String> uploadImage(File imageFile) async {
    try {
      // Firebase Storageへアップロード
      final ref = FirebaseStorage.instance
          .ref()
          .child('newsletter_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // アップロード実行
      final uploadTask = await ref.putFile(imageFile);
      
      // 公開URLを取得
      final imageUrl = await uploadTask.ref.getDownloadURL();
      
      return imageUrl;
    } catch (e) {
      throw ImageUploadException('画像のアップロードに失敗しました: $e');
    }
  }
}
```

### 画像の挿入と編集

```javascript
// カスタム画像ハンドラー
function imageHandler() {
  const input = document.createElement('input');
  input.setAttribute('type', 'file');
  input.setAttribute('accept', 'image/*');
  
  input.onchange = async () => {
    const file = input.files[0];
    if (file) {
      // 画像をBase64に変換
      const base64 = await fileToBase64(file);
      
      // Flutterに送信してアップロード
      window.postMessage({
        type: 'js-to-flutter',
        action: 'upload-image',
        data: { base64: base64 }
      }, '*');
    }
  };
  
  input.click();
}

// 画像挿入（Flutter側からの応答後）
function insertImage(imageUrl) {
  const range = quill.getSelection(true);
  quill.insertEmbed(range.index, 'image', imageUrl);
  quill.setSelection(range.index + 1);
}
```

### 画像リサイズ機能

```javascript
// Quill Image Resize Module設定
Quill.register('modules/imageResize', ImageResize);

// リサイズ可能な画像の挿入
quill.on('editor-change', function(eventName, ...args) {
  if (eventName === 'selection-change') {
    // 画像選択時にリサイズハンドルを表示
    const images = document.querySelectorAll('.ql-editor img');
    images.forEach(img => {
      img.style.cursor = 'pointer';
      // リサイズ機能を有効化
    });
  }
});
```

## 🎨 テンプレート機能

### テンプレート管理

```dart
// lib/features/editor/models/template.dart
class NewsletterTemplate {
  final String id;
  final String name;
  final String category; // 季節、行事、通常
  final String htmlContent;
  final Map<String, dynamic> variables;
  
  // テンプレート変数の置換
  String applyVariables(Map<String, String> values) {
    String result = htmlContent;
    variables.forEach((key, defaultValue) {
      final value = values[key] ?? defaultValue;
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }
}
```

### 季節別テンプレート

```dart
// 春のテンプレート例
final springTemplate = NewsletterTemplate(
  id: 'spring_01',
  name: '春の学級通信',
  category: 'seasonal',
  htmlContent: '''
    <div class="newsletter-header spring-theme">
      <h1>{{title}}</h1>
      <p class="date">{{date}}</p>
    </div>
    <div class="spring-decoration">
      <img src="/assets/cherry-blossom.svg" alt="桜">
    </div>
    <div class="content">
      {{content}}
    </div>
  ''',
  variables: {
    'title': '学級通信',
    'date': DateTime.now().toString(),
    'content': ''
  }
);
```

## 🔄 Delta形式とHTML変換

### Quill Deltaフォーマット

```javascript
// Delta形式の例
const delta = {
  ops: [
    { insert: '今日の給食は' },
    { insert: 'カレーライス', attributes: { bold: true } },
    { insert: 'でした。\n' },
    { insert: { image: 'https://example.com/curry.jpg' } },
    { insert: '\n子どもたちは大喜びでした。' }
  ]
};
```

### DeltaからHTMLへの変換

```javascript
// カスタムコンバーター
class DeltaToHtmlConverter {
  convert(delta) {
    const converter = new QuillDeltaToHtmlConverter(delta.ops, {
      multiLineParagraph: false,
      encodeHtml: true,
      customTag: (format, op) => {
        if (format === 'header') {
          return `h${op.attributes.header}`;
        }
        return undefined;
      }
    });
    
    // カスタムレンダラー
    converter.renderCustomWith((customOp, contextOp) => {
      if (customOp.insert.type === 'image') {
        const val = customOp.insert.value;
        return `<img src="${val}" class="newsletter-image" />`;
      }
      return undefined;
    });
    
    return converter.convert();
  }
}
```

## 💾 自動保存機能

### 自動保存の実装

```dart
// lib/features/editor/providers/auto_save_provider.dart
class AutoSaveProvider extends ChangeNotifier {
  Timer? _saveTimer;
  bool _hasUnsavedChanges = false;
  
  void startAutoSave() {
    _saveTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (_hasUnsavedChanges) {
        _saveContent();
      }
    });
  }
  
  void onContentChanged() {
    _hasUnsavedChanges = true;
    
    // デバウンス処理
    _saveTimer?.cancel();
    _saveTimer = Timer(Duration(seconds: 3), () {
      _saveContent();
    });
  }
  
  Future<void> _saveContent() async {
    try {
      final delta = await _editorService.getDelta();
      final html = await _editorService.getHtml();
      
      await _documentService.saveDraft({
        'delta': delta,
        'html': html,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _hasUnsavedChanges = false;
      notifyListeners();
    } catch (e) {
      // エラーハンドリング
    }
  }
}
```

## 🎯 高度な編集機能

### コラボレーション編集（将来実装）

```dart
// Firestore Realtime同期の概念
class CollaborativeEditingService {
  StreamSubscription? _deltaSubscription;
  
  void startCollaboration(String documentId) {
    _deltaSubscription = FirebaseFirestore.instance
        .collection('documents')
        .doc(documentId)
        .collection('deltas')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              _applyRemoteDelta(change.doc.data());
            }
          }
        });
  }
}
```

### カスタムブロック

```javascript
// 独自のブロック要素（例：注意事項ボックス）
class NoticeBlock extends Block {
  static create(value) {
    const node = super.create();
    node.setAttribute('class', 'notice-block');
    node.innerHTML = `
      <div class="notice-icon">⚠️</div>
      <div class="notice-content">${value}</div>
    `;
    return node;
  }
}

// Quillに登録
Quill.register(NoticeBlock);
```

## 🔧 エディタのカスタマイズ

### ツールバーのカスタマイズ

```javascript
// 教育現場向けツールバー
const customToolbar = [
  // 基本的な書式
  ['bold', 'italic', 'underline'],
  
  // 見出し（学級通信用）
  [{ 'header': 1 }, { 'header': 2 }],
  
  // リスト（連絡事項用）
  [{ 'list': 'ordered'}, { 'list': 'bullet' }],
  
  // 特殊ブロック
  ['blockquote'],  // お知らせ用
  
  // メディア
  ['image', 'link'],
  
  // カスタムボタン
  ['ai-rewrite', 'template', 'emoji']
];
```

### スタイルのカスタマイズ

```css
/* カスタムエディタスタイル */
.ql-editor {
  font-family: 'Noto Sans JP', sans-serif;
  font-size: 16px;
  line-height: 1.8;
  padding: 30px;
}

/* 学級通信用の見出しスタイル */
.ql-editor h1 {
  color: #2c5aa0;
  border-bottom: 3px solid #2c5aa0;
  padding-bottom: 10px;
  margin-bottom: 20px;
}

/* 画像の配置 */
.newsletter-image {
  max-width: 100%;
  height: auto;
  margin: 15px 0;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}
```

## 📱 モバイル対応

### タッチ操作の最適化

```javascript
// モバイル用の設定
if (isMobileDevice()) {
  quill.theme.modules.toolbar.container.classList.add('mobile-toolbar');
  
  // タッチイベントの処理
  quill.root.addEventListener('touchstart', handleTouchStart);
  quill.root.addEventListener('touchmove', handleTouchMove);
  quill.root.addEventListener('touchend', handleTouchEnd);
}

// ツールバーの表示/非表示
let toolbarTimeout;
quill.on('selection-change', (range) => {
  if (range) {
    showToolbar();
    clearTimeout(toolbarTimeout);
    toolbarTimeout = setTimeout(hideToolbar, 3000);
  }
});
```

## 🧪 テスト戦略

### エディタのE2Eテスト

```typescript
// e2e/editor.spec.ts
test('エディタで文章を編集できる', async ({ page }) => {
  // エディタページに移動
  await page.goto('/editor/new');
  
  // テキストを入力
  await page.locator('.ql-editor').type('テスト文章です。');
  
  // 太字を適用
  await page.locator('.ql-editor').selectText();
  await page.click('button[value="bold"]');
  
  // 結果を確認
  const html = await page.locator('.ql-editor').innerHTML();
  expect(html).toContain('<strong>テスト文章です。</strong>');
});
```

## 🎉 ベストプラクティス

### 1. パフォーマンス最適化
- 大きな文書では仮想スクロールを使用
- 画像は遅延読み込みを実装
- Deltaの差分更新で通信量を削減

### 2. アクセシビリティ
- キーボードショートカットを完全サポート
- スクリーンリーダー対応
- 高コントラストモード

### 3. エラーハンドリング
- 編集内容の定期的なバックアップ
- ネットワークエラー時のオフライン編集
- 競合解決メカニズム

---

*次のステップ: [APIリファレンス](../reference/api/endpoints.md)でバックエンドとの連携を学ぶ*