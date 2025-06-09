# 折りたたみ式AI補助UI仕様書

## 1. 概要

学級通信エディタ画面に折りたたみ式のAI補助パネルを実装します。これにより、ユーザーは必要に応じてAI補助機能を呼び出し、コンテンツの生成・編集を効率化できます。

## 2. UI設計

### 2.1 基本レイアウト

```
┌─────────────────────────────────────────────┐
│ [エディタツールバー]                            │
│ ┌─────────────────────────────────────────┐ │
│ │                                         │ │
│ │ [Quill.js エディタ領域]                    │ │
│ │                                         │ │
│ └─────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────┐ │
│ │ ▼ AI補助（クリックで展開）                   │ │
│ └─────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────┐ │
│ │ [折りたたみ展開時のAI補助パネル]             │ │
│ │ ○ 挨拶文を生成                            │ │
│ │ ○ 今月の予定を箇条書き                      │ │
│ │ ○ 文章を読みやすくリライト                   │ │
│ │ ○ カスタム指示: [                    ]     │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### 2.2 状態

- **折りたたみ状態**: デフォルトではパネルは折りたたまれている
- **展開状態**: クリックすると下に展開される
- **処理中状態**: AI処理中はローディングインジケータを表示

## 3. 機能一覧

### 3.1 定型機能ボタン

| 機能ボタン | 説明 | 処理内容 |
|----------|------|---------|
| 挨拶文を生成 | 月に合わせた挨拶文を生成 | 現在の月を検出し、季節に合った挨拶文をGeminiで生成 |
| 今月の予定を箇条書き | 予定を箇条書きリストで生成 | 箇条書き形式の予定リストをGeminiで生成 |
| 文章を読みやすくリライト | 選択テキストをリライト | 選択中のテキストをより読みやすく書き換え |
| 見出しを自動生成 | テキストから見出しを生成 | 選択テキストから適切な見出しを生成 |

### 3.2 カスタム指示入力

- テキスト入力フィールドでカスタム指示を入力可能
- 「生成」ボタンでカスタム指示に基づいてコンテンツ生成

### 3.3 季節テーマ切り替え

- 季節ボタン（春・夏・秋・冬）でカラーテーマを切り替え
- 対応する色彩パレットを即時適用

## 4. インタラクション仕様

### 4.1 AI補助パネルの展開/折りたたみ

```dart
// 展開/折りたたみ状態管理
bool _isExpanded = false;

// トグル関数
void _toggleExpand() {
  setState(() {
    _isExpanded = !_isExpanded;
  });
}

// UI実装
Widget build(BuildContext context) {
  return Column(
    children: [
      // 展開/折りたたみヘッダー
      InkWell(
        onTap: _toggleExpand,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              ),
              SizedBox(width: 8.0),
              Text('AI補助'),
            ],
          ),
        ),
      ),
      
      // 折りたたみコンテンツ
      AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: _isExpanded ? null : 0.0,
        child: _isExpanded
            ? _buildAIAssistantPanel()
            : SizedBox.shrink(),
      ),
    ],
  );
}
```

### 4.2 AI機能実行フロー

```dart
// AI機能実行
Future<void> _executeAIFunction(AIFunctionType type, {String? customPrompt}) async {
  setState(() {
    _isProcessing = true;
  });
  
  try {
    String result;
    
    switch (type) {
      case AIFunctionType.greeting:
        result = await _aiService.generateGreeting();
        break;
      case AIFunctionType.schedule:
        result = await _aiService.generateSchedule();
        break;
      case AIFunctionType.rewrite:
        final selectedText = _editorController.getSelectedText();
        if (selectedText.isEmpty) {
          _showSnackBar('テキストを選択してください');
          return;
        }
        result = await _aiService.rewriteText(selectedText);
        break;
      case AIFunctionType.custom:
        if (customPrompt == null || customPrompt.isEmpty) {
          _showSnackBar('指示を入力してください');
          return;
        }
        result = await _aiService.generateCustomContent(customPrompt);
        break;
      default:
        throw Exception('Unknown AI function type');
    }
    
    // 結果をエディタに挿入
    _insertToEditor(result);
    
  } catch (e) {
    _showSnackBar('エラーが発生しました: $e');
  } finally {
    setState(() {
      _isProcessing = false;
    });
  }
}
```

### 4.3 エディタへの挿入

```dart
// エディタへの挿入
void _insertToEditor(String content) {
  // 現在のカーソル位置または選択位置を取得
  final position = _editorController.getSelectionOffset();
  
  // エディタに挿入
  _editorController.insertHtml(content, position);
  
  // 挿入後のUIフィードバック
  _showSnackBar('コンテンツを挿入しました');
}
```

## 5. アニメーション仕様

### 5.1 折りたたみアニメーション

- **展開時**: 下方向にスライドダウン（200ms）
- **折りたたみ時**: 上方向にスライドアップ（200ms）
- **イージング**: ease-in-out

### 5.2 処理中アニメーション

- ボタン上にCircularProgressIndicator表示
- 処理完了時に成功/失敗アニメーション（グリーンチェック/レッドエラー）

## 6. 実装詳細

### 6.1 コンポーネント構成

```
AIAssistantPanel/
├── AIAssistantPanelHeader.dart     # 折りたたみヘッダー
├── AIAssistantPanelContent.dart    # 展開時のコンテンツ
├── AIFunctionButton.dart           # AI機能ボタン
├── SeasonThemeSelector.dart        # 季節テーマセレクタ
└── CustomPromptInput.dart          # カスタムプロンプト入力
```

### 6.2 主要クラス

#### AIAssistantPanel

```dart
class AIAssistantPanel extends StatefulWidget {
  final QuillEditorController editorController;
  
  const AIAssistantPanel({
    Key? key,
    required this.editorController,
  }) : super(key: key);
  
  @override
  _AIAssistantPanelState createState() => _AIAssistantPanelState();
}

class _AIAssistantPanelState extends State<AIAssistantPanel> {
  bool _isExpanded = false;
  bool _isProcessing = false;
  final _aiService = AIAssistantService();
  final _customPromptController = TextEditingController();
  
  // 実装は前述のコード参照
}
```

### 6.3 状態管理

```dart
// AIAssistantProvider
class AIAssistantProvider extends ChangeNotifier {
  bool _isProcessing = false;
  String? _lastResult;
  String? _error;
  
  bool get isProcessing => _isProcessing;
  String? get lastResult => _lastResult;
  String? get error => _error;
  
  Future<void> executeFunction(AIFunctionType type, {String? customPrompt}) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();
    
    try {
      // AI処理実行
      // ...
      
      _lastResult = result;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
```

## 7. 品質・ユーザビリティ対策

### 7.1 エラーハンドリング

- **ネットワークエラー**: オフライン時の適切なメッセージ
- **APIエラー**: レート制限などの説明
- **タイムアウト**: 30秒でタイムアウト処理

### 7.2 アクセシビリティ

- **スクリーンリーダー対応**: 全ボタンに適切なラベル
- **キーボード操作**: Tabキーで順次移動可能
- **色コントラスト**: WCAG AAレベルのコントラスト比

### 7.3 ユーザーフィードバック

- **トースト表示**: 処理完了時に簡潔なメッセージ
- **成功アニメーション**: 操作成功時のビジュアルフィードバック
- **ヘルプツールチップ**: 機能説明のホバーツールチップ

## 8. 実装スケジュール

1. **Day 1**: 基本UI構造実装（折りたたみ/展開）
2. **Day 2**: AI機能ボタン実装
3. **Day 3**: エディタ連携
4. **Day 4**: アニメーション・UIポリッシュ
5. **Day 5**: テスト・品質改善 