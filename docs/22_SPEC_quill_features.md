# Quill.js エディタ機能仕様書

**カテゴリ**: SPEC | **レイヤー**: DETAIL | **更新**: 2025-01-09  
**担当**: 亀ちゃん | **依存**: 21_SPEC_quill_setup.md | **タグ**: #frontend #quill #editor

## 🎯 TL;DR（30秒で読める要約）

- **目的**: Quill.js WYSIWYGエディタの全機能仕様を定義
- **対象**: フロントエンド実装者、UI/UX担当者  
- **成果物**: ツールバー設定、フォーマット機能、ショートカット一覧
- **次のアクション**: 23_SPEC_quill_implementation.mdで実装詳細確認

## 🔗 関連ドキュメント

| 種別 | ファイル名 | 関係性 |
|------|-----------|--------|
| 依存 | 21_SPEC_quill_setup.md | Quill.js基本セットアップ |
| 派生 | 23_SPEC_quill_implementation.md | Flutter統合実装 |
| 関連 | 21_SPEC_ui_component_design.md | 全体UI設計 |

## 📊 メタデータ

- **複雑度**: High
- **推定読了時間**: 8分
- **更新頻度**: 中

---

## 1. ツールバー設計

### 1.1 基本ツールバー構成

```javascript
// Quill Snow テーマ カスタムツールバー
const toolbarOptions = [
  // 見出し・テキストフォーマット
  [{ 'header': [1, 2, 3, false] }],
  
  // 基本フォーマット
  ['bold', 'italic', 'underline'],
  
  // リスト
  [{ 'list': 'ordered'}, { 'list': 'bullet' }],
  
  // インデント
  [{ 'indent': '-1'}, { 'indent': '+1' }],
  
  // カスタム機能
  ['ai-assist', 'image', 'clean']
];
```

### 1.2 ツールバーボタン詳細

| ボタン | アイコン | 機能 | ショートカット | 優先度 |
|--------|---------|------|-------------|--------|
| **H1** | `H1` | 大見出し | `Ctrl+1` | 高 |
| **H2** | `H2` | 中見出し | `Ctrl+2` | 高 |
| **H3** | `H3` | 小見出し | `Ctrl+3` | 中 |
| **B** | `Bold` | 太字 | `Ctrl+B` | 高 |
| **I** | `Italic` | 斜体 | `Ctrl+I` | 中 |
| **U** | `Underline` | 下線 | `Ctrl+U` | 低 |
| **•** | `Bullet` | 箇条書き | `Ctrl+Shift+8` | 高 |
| **1.** | `Ordered` | 番号リスト | `Ctrl+Shift+7` | 高 |
| **🤖** | `AI` | AI補助 | `Ctrl+Space` | 高 |
| **🖼** | `Image` | 画像挿入 | `Ctrl+Shift+I` | 中 |

### 1.3 カスタムボタン実装

```javascript
// AI補助ボタン
const AiAssistButton = Quill.import('ui/icons');
AiAssistButton['ai-assist'] = `<svg>...</svg>`;

// カスタムボタンハンドラー
quill.getModule('toolbar').addHandler('ai-assist', function() {
  // AI補助パネルを表示
  showAiAssistPanel();
});
```

---

## 2. エディタフォーマット機能

### 2.1 対応HTMLタグ（制約準拠）

要件書のHTML制約に準拠した許可タグのみサポート：

| フォーマット | 出力HTMLタグ | Quill対応 | 用途 |
|-------------|-------------|-----------|------|
| **見出し1** | `<h1>` | ✅ | 通信タイトル |
| **見出し2** | `<h2>` | ✅ | セクション見出し |
| **見出し3** | `<h3>` | ✅ | サブセクション |
| **段落** | `<p>` | ✅ | 本文 |
| **太字** | `<strong>` | ✅ | 重要語句 |
| **斜体** | `<em>` | ✅ | 強調 |
| **箇条書き** | `<ul><li>` | ✅ | リスト |
| **番号リスト** | `<ol><li>` | ✅ | 順序リスト |
| **改行** | `<br>` | ✅ | 行区切り |

### 2.2 禁止フォーマット

以下は制約により**使用禁止**：

- `<div>`, `<span>` タグ
- `style`, `class` 属性
- カラー変更
- フォントサイズ変更
- テーブル機能

### 2.3 Delta形式とHTML変換

```javascript
// 許可タグのみのHTML出力
function sanitizeQuillHTML(html) {
  const allowedTags = ['h1', 'h2', 'h3', 'p', 'strong', 'em', 'ul', 'ol', 'li', 'br'];
  
  // DOMParserでパース
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
```

---

## 3. キーボードショートカット

### 3.1 基本ショートカット

| ショートカット | 機能 | 対象OS |
|---------------|------|--------|
| `Ctrl+B` / `Cmd+B` | 太字切り替え | Win/Mac |
| `Ctrl+I` / `Cmd+I` | 斜体切り替え | Win/Mac |
| `Ctrl+U` / `Cmd+U` | 下線切り替え | Win/Mac |
| `Ctrl+Z` / `Cmd+Z` | 元に戻す | Win/Mac |
| `Ctrl+Y` / `Cmd+Shift+Z` | やり直し | Win/Mac |
| `Ctrl+A` / `Cmd+A` | 全選択 | Win/Mac |

### 3.2 カスタムショートカット

```javascript
// カスタムキーボードモジュール
const customKeyboard = {
  bindings: {
    // AI補助呼び出し
    'ai-assist': {
      key: ' ',
      ctrlKey: true,
      handler: function(range, context) {
        showAiAssistPanel();
        return false;
      }
    },
    
    // 見出し1
    'header-1': {
      key: '1',
      ctrlKey: true,
      handler: function(range, context) {
        this.quill.format('header', 1);
        return false;
      }
    },
    
    // 箇条書き
    'bullet-list': {
      key: '8',
      ctrlKey: true,
      shiftKey: true,
      handler: function(range, context) {
        this.quill.format('list', 'bullet');
        return false;
      }
    }
  }
};
```

---

## 4. AI統合機能

### 4.1 AI補助ボタン機能

```javascript
// AI補助機能の実装
class QuillAiAssistant {
  constructor(quill) {
    this.quill = quill;
    this.setupToolbar();
  }
  
  setupToolbar() {
    const toolbar = this.quill.getModule('toolbar');
    toolbar.addHandler('ai-assist', this.showAiPanel.bind(this));
  }
  
  showAiPanel() {
    // 現在の選択範囲を取得
    const range = this.quill.getSelection();
    const selectedText = this.quill.getText(range.index, range.length);
    
    // AI補助パネルを表示
    window.flutter_inappwebview.callHandler('showAiAssist', {
      selectedText: selectedText,
      cursorPosition: range.index
    });
  }
  
  // Flutter側からのAI結果挿入
  insertAiContent(content, position) {
    this.quill.insertText(position, content);
    this.quill.setSelection(position + content.length);
  }
}
```

### 4.2 リアルタイム保存

```javascript
// 自動保存機能
class QuillAutoSave {
  constructor(quill, saveInterval = 3000) {
    this.quill = quill;
    this.saveInterval = saveInterval;
    this.lastSaveTime = Date.now();
    this.setupAutoSave();
  }
  
  setupAutoSave() {
    this.quill.on('text-change', (delta, oldDelta, source) => {
      if (source === 'user') {
        this.scheduleSave();
      }
    });
  }
  
  scheduleSave() {
    clearTimeout(this.saveTimeout);
    this.saveTimeout = setTimeout(() => {
      this.saveDocument();
    }, this.saveInterval);
  }
  
  saveDocument() {
    const delta = this.quill.getContents();
    const html = this.quill.root.innerHTML;
    
    // Flutter側に保存データを送信
    window.flutter_inappwebview.callHandler('saveDocument', {
      delta: JSON.stringify(delta),
      html: sanitizeQuillHTML(html),
      timestamp: new Date().toISOString()
    });
  }
}
```

---

## 5. プレビュー機能

### 5.1 リアルタイムHTMLプレビュー

```javascript
// プレビューペインとの同期
class QuillPreview {
  constructor(quill) {
    this.quill = quill;
    this.setupPreview();
  }
  
  setupPreview() {
    this.quill.on('text-change', () => {
      this.updatePreview();
    });
  }
  
  updatePreview() {
    const html = sanitizeQuillHTML(this.quill.root.innerHTML);
    
    // Flutter側のプレビューを更新
    window.flutter_inappwebview.callHandler('updatePreview', {
      html: html
    });
  }
}
```

### 5.2 季節テーマ適用

```javascript
// 季節テーマの適用
function applySeasonTheme(season) {
  const themes = {
    spring: {
      '--primary-color': '#ff9eaa',
      '--secondary-color': '#a5d8ff',
      '--accent-color': '#ffdb4d'
    },
    summer: {
      '--primary-color': '#51cf66',
      '--secondary-color': '#339af0',
      '--accent-color': '#ff922b'
    },
    autumn: {
      '--primary-color': '#e67700',
      '--secondary-color': '#d9480f',
      '--accent-color': '#fff3bf'
    },
    winter: {
      '--primary-color': '#4dabf7',
      '--secondary-color': '#e7f5ff',
      '--accent-color': '#91a7ff'
    }
  };
  
  const root = document.documentElement;
  Object.entries(themes[season]).forEach(([key, value]) => {
    root.style.setProperty(key, value);
  });
}
```

---

## 6. エラーハンドリング

### 6.1 入力検証

```javascript
// 無効な操作の防止
function validateQuillInput(delta) {
  const errors = [];
  
  // 禁止タグのチェック
  if (delta.ops.some(op => op.attributes && op.attributes.color)) {
    errors.push('カラー変更は許可されていません');
  }
  
  // 画像のサイズ制限
  if (delta.ops.some(op => op.insert && op.insert.image)) {
    errors.push('画像挿入は現在開発中です');
  }
  
  return errors;
}
```

### 6.2 復旧機能

```javascript
// エラー時の復旧
class QuillErrorRecovery {
  constructor(quill) {
    this.quill = quill;
    this.setupErrorHandling();
  }
  
  setupErrorHandling() {
    window.addEventListener('error', (event) => {
      this.handleError(event.error);
    });
  }
  
  handleError(error) {
    console.error('Quill Error:', error);
    
    // Flutter側にエラー通知
    window.flutter_inappwebview.callHandler('onQuillError', {
      message: error.message,
      stack: error.stack
    });
  }
}
```

---

## 7. パフォーマンス最適化

### 7.1 大型ドキュメント対応

- **初期化遅延**: 5000文字以上で部分読み込み
- **レンダリング最適化**: 仮想スクロール実装
- **メモリ管理**: 履歴制限（最大50回まで）

### 7.2 モバイル対応

```javascript
// タッチデバイス最適化
const mobileConfig = {
  theme: 'snow',
  modules: {
    toolbar: {
      container: '#mobile-toolbar',
      handlers: {
        // モバイル用ハンドラー
      }
    }
  },
  formats: ['header', 'bold', 'italic', 'list'],
  placeholder: 'ここに学級通信の内容を入力...'
};
```

このQuill.js機能仕様により、要件書で求められるWYSIWYGエディタの全機能が実装可能になります。 