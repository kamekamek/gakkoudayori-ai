# UI コンポーネント設計仕様書

**カテゴリ**: SPEC | **レイヤー**: DETAIL | **更新**: 2025-01-09  
**担当**: Claude | **依存**: 01_REQUIREMENT_overview.md, 20_SPEC_quill_integration.md | **タグ**: #frontend #ui #flutter

## 🎯 TL;DR（30秒で読める要約）

- **目的**: Layout B（3カラム構成）のUIコンポーネント設計仕様を定義
- **対象**: フロントエンド開発者、UIデザイナー  
- **成果物**: 9つのコンポーネント仕様＋状態管理＋実装優先順位
- **次のアクション**: AppShell Grid基盤から実装開始

## 🔗 関連ドキュメント

| 種別 | ファイル名 | 関係性 |
|------|-----------|--------|
| 依存 | 01_REQUIREMENT_overview.md | 全体要件・機能要求の前提 |
| 依存 | 20_SPEC_quill_integration.md | Quillエディタ技術仕様 |
| 関連 | 10_DESIGN_color_palettes.md | デザインシステム・カラー定義 |

## 📊 メタデータ

- **複雑度**: High
- **推定読了時間**: 8分
- **更新頻度**: 中

## 🎯 画面全体レイアウト（Layout B）

```
┌─────────────────────────────────────────────────────────────┐
│ AppShell - 3カラムGrid (1280px基準)                          │
├─────────────┬───────────────────────────┬─────────────────────┤
│ DraftNav    │ Center Editor Area        │ PreviewPane         │
│ (20%)       │ (55%)                     │ (25%)               │
│             │                           │                     │
│ ・過去通信   │ QToolbar                  │ HTML Preview        │
│ ・履歴      │ [B|I|U|H1|H2|・|画像]    │ ・Desktop/Mobile    │
│ ・検索      │                           │ ・印刷プレビュー    │
│             │ QEditor                   │                     │
│ ・新規作成  │ [Quill Rich Editor]       │                     │
│ ・CRUD操作  │                           │                     │
│             │ AiQuickPanel              │ SaveToast           │
│             │ [句読点|要約|見出し]      │ (右下通知)          │
│             │                           │                     │
│             │ AiChatDrawer (Overlay)    │                     │
└─────────────┴───────────────────────────┴─────────────────────┘
```

## 🧩 コンポーネント一覧 & 技術インターフェース

| ID | コンポーネント名 | 主機能 | 状態 | 外部依存 |
|----|----------------|--------|------|----------|
| `AppShell` | 画面全体レイアウト | 3カラム幅調整 | `desktop/tablet/mobile` | - |
| `DraftNav` | 過去通信リスト | CRUD + 履歴 | `load/selected/editing/saving` | Firestore |
| `QToolbar` | Quillツールバー | フォーマット | - | Quill Module |
| `QEditor` | 本文入力エリア | リッチテキスト | `idle/busy` | Quill |
| `AiQuickPanel` | ワンクリック整形 | AI機能実行 | `idle/loading` | Gemini Pro |
| `AiChatDrawer` | 相談チャット | フリーフォーム | `closed/open/thinking` | Gemini Pro |
| `PreviewPane` | HTMLプレビュー | iframe表示 | `desktop/mobile` | Sanitized iframe |
| `SaveToast` | 保存通知 | トースト表示 | `success/error` | - |
| `NetworkGuard` | オフライン対応 | ローカル保存 | `online/offline/syncing` | Service Worker |

## 🔧 詳細技術仕様

### AppShell (画面全体レイアウト)

```dart
class AppShellState {
  LayoutMode currentMode;  // desktop, tablet, mobile
  double navWidth;         // 20% (min: 200px, max: 400px)
  double centerWidth;      // 55% (min: 600px)
  double previewWidth;     // 25% (min: 300px, max: 500px)
  bool isPreviewCollapsed;
}

// レスポンシブブレークポイント
class Breakpoints {
  static const double mobile = 768;
  static const double tablet = 1024;
  static const double desktop = 1280;
}
```

### DraftNav (ドラフト一覧・履歴)

```dart
class DraftNavState {
  List<Document> documents;
  Document? selectedDocument;
  String searchQuery;
  bool isLoading;
  DocumentFilter filter; // all, recent, favorites
}

// 主要メソッド
- loadDocuments() - Firestore読み込み
- selectDocument(String id) - 通信選択
- createNewDocument() - 新規作成
- deleteDocument(String id) - 削除（確認ダイアログ）
```

**キーボード操作**
- `↑/↓` - リスト選択移動
- `Enter` - 選択通信を開く
- `Ctrl+N` - 新規作成
- `Delete` - 選択通信削除

### QEditor + AiQuickPanel (コアエディタ)

```dart
class QEditorState {
  QuillController controller;
  bool isAiProcessing;
  String? errorMessage;
  DateTime? lastSaved;
}

// AI機能ボタン
List<AiFunction> functions = [
  AiFunction('punctuation', '句読点整形', Icons.format_textdirection_l_to_r),
  AiFunction('summary', '要約生成', Icons.summarize),
  AiFunction('heading', '見出し生成', Icons.title),
];
```

### AiQuickPanel (ワンクリック整形) - 詳細実装

**配置**: エディタ下部の水平ボタン群  
**動作**: 選択テキストまたは全文に対してワンクリックAI処理

```dart
class AiQuickPanelState {
  Map<String, bool> processingStates; // 各機能の処理状態
  String? lastError;
}

// AI機能ボタン詳細
List<AiFunction> quickFunctions = [
  AiFunction(
    id: 'punctuation',
    label: '句読点整形',
    icon: Icons.format_textdirection_l_to_r,
    prompt: '句読点を適切に追加・修正してください',
    targetType: TargetType.selected, // selected, all
  ),
  AiFunction(
    id: 'summary', 
    label: '要約生成',
    icon: Icons.summarize,
    prompt: 'この内容を3行で要約してください',
    targetType: TargetType.all,
  ),
  AiFunction(
    id: 'heading',
    label: '見出し生成', 
    icon: Icons.title,
    prompt: '適切な見出しを生成してください',
    targetType: TargetType.selected,
  ),
  AiFunction(
    id: 'greeting',
    label: '挨拶文生成',
    icon: Icons.waving_hand,
    prompt: '月に合わせた挨拶文を生成してください',
    targetType: TargetType.cursor,
  ),
];

// 実行メソッド
Future<void> executeQuickFunction(String functionId) async {
  final function = quickFunctions.firstWhere((f) => f.id == functionId);
  
  setState(() {
    processingStates[functionId] = true;
  });
  
  try {
    String targetText;
    switch (function.targetType) {
      case TargetType.selected:
        targetText = _editorController.getSelectedText();
        if (targetText.isEmpty) {
          _showSnackBar('テキストを選択してください');
          return;
        }
        break;
      case TargetType.all:
        targetText = _editorController.getAllText();
        break;
      case TargetType.cursor:
        targetText = ''; // カーソル位置に挿入
        break;
    }
    
    final result = await _aiService.processText(
      targetText, 
      function.prompt,
    );
    
    _insertOrReplaceText(result, function.targetType);
    _showSuccessToast('${function.label}が完了しました');
    
  } catch (e) {
    _showErrorToast('${function.label}に失敗しました: $e');
  } finally {
    setState(() {
      processingStates[functionId] = false;
    });
  }
}
```

### AiChatDrawer (フリーフォーム相談) - 詳細実装

**配置**: 画面右側のオーバーレイドロワー  
**動作**: 折りたたみ式チャットインターフェース

```dart
class AiChatDrawerState {
  bool isOpen;
  List<ChatMessage> messages;
  bool isThinking;
  String currentInput;
  final maxWidth = 400.0;
}

class ChatMessage {
  String id;
  ChatRole role; // user, assistant
  String content;
  DateTime timestamp;
  MessageType type; // text, code, suggestion
}

// 折りたたみ/展開制御
Widget buildChatDrawer() {
  return AnimatedContainer(
    duration: Duration(milliseconds: 300),
    width: isOpen ? maxWidth : 60,
    height: MediaQuery.of(context).size.height,
    decoration: BoxDecoration(
      color: AppColors.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 8,
          offset: Offset(-2, 0),
        ),
      ],
    ),
    child: isOpen ? _buildChatInterface() : _buildCollapsedTab(),
  );
}

// チャットインターフェース
Widget _buildChatInterface() {
  return Column(
    children: [
      // ヘッダー
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.white),
            SizedBox(width: 8),
            Text('AI相談', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Spacer(),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => isOpen = false),
            ),
          ],
        ),
      ),
      
      // メッセージリスト
      Expanded(
        child: ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: messages.length,
          itemBuilder: (context, index) => _buildMessageBubble(messages[index]),
        ),
      ),
      
      // AI処理中インジケータ
      if (isThinking)
        Container(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('考え中...', style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      
      // 入力フィールド
      Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  hintText: '何でも相談してください...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                maxLines: null,
                onSubmitted: _sendMessage,
              ),
            ),
            SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: isThinking ? null : () => _sendMessage(currentInput),
              child: Icon(Icons.send),
            ),
          ],
        ),
      ),
    ],
  );
}

// メッセージ送信処理
Future<void> _sendMessage(String text) async {
  if (text.trim().isEmpty) return;
  
  // ユーザーメッセージ追加
  final userMessage = ChatMessage(
    id: generateId(),
    role: ChatRole.user,
    content: text,
    timestamp: DateTime.now(),
    type: MessageType.text,
  );
  
  setState(() {
    messages.add(userMessage);
    currentInput = '';
    isThinking = true;
  });
  
  _inputController.clear();
  
  try {
    // エディタの現在内容を context として渡す
    final editorContent = _editorController.getAllText();
    final contextPrompt = '''
現在編集中の学級通信:
$editorContent

ユーザーの質問: $text

学級通信作成の観点から回答してください。
''';
    
    final response = await _aiService.chat(contextPrompt);
    
    final assistantMessage = ChatMessage(
      id: generateId(),
      role: ChatRole.assistant,
      content: response,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );
    
    setState(() {
      messages.add(assistantMessage);
    });
    
  } catch (e) {
    _showErrorToast('回答の取得に失敗しました: $e');
  } finally {
    setState(() {
      isThinking = false;
    });
  }
}
```

## 🎨 デザインシステム

### カラーパレット（WCAG AA準拠）
```dart
class AppColors {
  static const primary = Color(0xFF4A90E2);      // メインブルー
  static const accent = Color(0xFFFF6B6B);       // アクセント赤
  static const background = Color(0xFFFAFBFC);   // 背景
  static const textPrimary = Color(0xFF2C3E50);  // テキスト（コントラスト4.5:1）
}
```

### タイポグラフィ
```dart
static const h1 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
static const body = TextStyle(fontSize: 16, height: 1.6);
```

## 🔄 状態遷移フロー

### エディタ全体フロー
```
[アプリ起動] → [ドラフト一覧読み込み] → [通信選択] → [エディタ表示]
     ↓              ↓                    ↓            ↓
[新規作成] → [空エディタ] → [編集開始] → [リアルタイム保存]
     ↓              ↓            ↓            ↓
[AI機能実行] → [結果反映] → [プレビュー確認] → [完成・公開]
```

### AI処理フロー
```
[AI機能ボタン押下] → [入力内容検証] → [Gemini API呼び出し]
     ↓                  ↓               ↓
[レスポンス受信] → [エディタに反映] → [保存実行]
     ↓
[エラー処理] → [エラートースト表示]
```

## 📱 レスポンシブ対応

| 画面サイズ | レイアウト | 調整内容 |
|-----------|-----------|----------|
| Desktop (1280px+) | 3カラム表示 | 通常表示 |
| Tablet (768-1024px) | 3カラム | Preview折りたたみ可能 |
| Mobile (<768px) | 単一ペイン | タブ切替式 |

## 🧪 テスト要件

### 単体テスト対象
- 各コンポーネントの状態管理ロジック
- AI機能の入力検証・エラーハンドリング
- レスポンシブレイアウト切替

### ウィジェットテスト対象  
- ユーザーインタラクション（タップ、キーボード）
- 画面遷移・状態変化
- アクセシビリティ属性

## 🚀 実装優先順位

### Phase 1 (MVP - 2週間)
1. **AppShell Grid基盤** - 3カラムレイアウト基盤
2. **QEditor基本機能** - Quillエディタ統合
3. **DraftNav CRUD** - 基本的な通信管理

### Phase 2 (AI機能 - 2週間)  
4. **AiQuickPanel実装** - ワンクリック整形機能
5. **PreviewPane表示** - HTMLプレビュー
6. **Gemini API連携** - AI機能の実装

### Phase 3 (UX向上 - 1週間)
7. **AiChatDrawer実装** - フリーフォーム相談
8. **NetworkGuard対応** - オフライン機能
9. **アクセシビリティ強化** - WCAG準拠

## 📋 次のアクション

1. **UI-001**: AppShell Grid基盤レイアウト実装（Story Point: 3）
2. **UI-004**: QEditor + AiQuickPanel実装（Story Point: 8）
3. **UI-002**: DraftNav実装（Story Point: 5）

各タスクはTDD原則に従い、テストファーストで実装する。