# Quill.js環境セットアップ

**カテゴリ**: SPEC | **レイヤー**: DETAIL | **更新**: 2025-06-09  
**担当**: 亀ちゃん | **依存**: 20_SPEC_quill_summary.md | **タグ**: #frontend #setup #webview

## 🎯 TL;DR（30秒で読める要約）

- **目的**: Flutter WebView内でQuill.js環境を構築
- **対象**: 開発者（フロントエンド設定）  
- **成果物**: 動作するQuill.jsエディタHTML/CSS/JS
- **次のアクション**: 22_SPEC_quill_features.mdで機能実装

## 🔗 関連ドキュメント

| 種別 | ファイル名 | 関係性 |
|------|-----------|--------|
| 依存 | 20_SPEC_quill_summary.md | 技術概要 |
| 関連 | 10_DESIGN_color_palettes.md | 季節テーマ色定義 |
| 派生 | 22_SPEC_quill_features.md | 機能実装 |

## 📁 ディレクトリ構造

```
frontend/
  web/
    quill/
      index.html        # Quill.jsメインHTML
      quill_bridge.js   # Flutter通信ブリッジ
      styles.css        # カスタムスタイル + 季節テーマ
      assets/           # 画像・アイコン等
```

## 🔧 セットアップ手順

### 1. HTML基盤 (`index.html`)

```html
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
  <script src="quill_bridge.js"></script>
</body>
</html>
```

### 2. 基本CSS (`styles.css`)

```css
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
.theme-spring .ql-editor { 
  background-color: #fff5f5; 
  color: #2d3748; 
}

.theme-summer .ql-editor { 
  background-color: #f0fff4; 
  color: #1a202c; 
}

.theme-autumn .ql-editor { 
  background-color: #fffaf0; 
  color: #2d3748; 
}

.theme-winter .ql-editor { 
  background-color: #f7fafc; 
  color: #1a202c; 
}

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

### 3. 基本JavaScript初期化

```javascript
// quill_bridge.js
let quill;

// Quill エディタ初期化
function initializeQuill() {
  quill = new Quill('#editor-container', {
    theme: 'snow',
    placeholder: '学級通信の内容を入力してください...',
    modules: {
      toolbar: [
        ['bold', 'italic', 'underline'],
        [{ 'header': 1 }, { 'header': 2 }, { 'header': 3 }],
        [{ 'list': 'ordered' }, { 'list': 'bullet' }],
        [{ 'color': [] }, { 'background': [] }],
        ['clean']
      ]
    }
  });
  
  console.log('Quill initialized');
  return quill;
}

// DOM読み込み完了後に初期化
document.addEventListener('DOMContentLoaded', function() {
  initializeQuill();
});
```

## 🧪 動作確認

### 1. HTML単体テスト
```bash
# ローカルサーバー起動（Python 3）
cd frontend/web/quill
python -m http.server 8000

# ブラウザでテスト
open http://localhost:8000
```

### 2. 確認項目
- [ ] Quill.jsエディタが表示される
- [ ] ツールバーが正常に動作する
- [ ] テキスト入力・書式設定ができる
- [ ] 季節テーマCSSが適用される
- [ ] コンソールエラーがない

### 3. Flutter依存関係追加

```yaml
# pubspec.yaml
dependencies:
  flutter_inappwebview: ^4.9.0
  provider: ^6.0.0
```

## ⚠️ 注意事項

1. **CDN依存**: Quill.js 2.0.0の安定性確認必要
2. **WebView設定**: Android/iOSでの動作差異に注意
3. **セキュリティ**: JavaScript Bridge設定を慎重に
4. **パフォーマンス**: 大きなHTMLコンテンツでの動作検証

## ✅ 完了チェック

- [ ] HTMLファイル作成完了
- [ ] CSSスタイル適用完了
- [ ] JavaScript基本動作確認
- [ ] Flutter依存関係追加
- [ ] ローカルテスト通過

## 📊 メタデータ

- **複雑度**: Medium
- **推定読了時間**: 8分
- **更新頻度**: 低 