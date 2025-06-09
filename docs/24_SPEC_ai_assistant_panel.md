# AI補助パネル設計書

**カテゴリ**: SPEC | **レイヤー**: DETAIL | **更新**: 2025-01-09  
**担当**: 亀ちゃん | **依存**: 22_SPEC_quill_features.md | **タグ**: #ui #ai #panel

## 🎯 TL;DR（30秒で読める要約）

- **目的**: 折りたたみ式AI補助パネルのUI・UX設計
- **対象**: フロントエンド開発者、UI/UX担当者  
- **成果物**: AI補助パネルコンポーネント、状態管理、アニメーション仕様
- **次のアクション**: Flutter実装開始

## 🔗 関連ドキュメント

| 種別 | ファイル名 | 関係性 |
|------|-----------|--------|
| 依存 | 22_SPEC_quill_features.md | Quill機能仕様 |
| 依存 | 23_SPEC_quill_implementation.md | Quill実装 |
| 関連 | 30_API_endpoints.md | AI API |

## 📊 メタデータ

- **複雑度**: Medium
- **推定読了時間**: 8分
- **更新頻度**: 中

---

## 1. UI設計

### 1.1 基本レイアウト

```
┌──────────────────────────────────────────────┐
│ [エディタツールバー]                             │
│ ┌────────────────────────────────────────────┐ │
│ │                                            │ │
│ │ [Quill.js WebView エディタ領域]               │ │
│ │                                            │ │
│ └────────────────────────────────────────────┘ │
│ ┌────────────────────────────────────────────┐ │
│ │ 🤖 AI補助 ▼                                │ │
│ └────────────────────────────────────────────┘ │
│ ┌────────────────────────────────────────────┐ │
│ │ [AI補助パネル - 展開時]                       │ │
│ │ ┌─────────┐ ┌─────────┐ ┌─────────┐        │ │
│ │ │挨拶文生成│ │予定作成 │ │文章改善 │         │ │
│ │ └─────────┘ └─────────┘ └─────────┘        │ │
│ │ ┌────────────────────────────────────────┐   │ │
│ │ │カスタム指示: [例：もっと親しみやすく] [生成]│   │ │
│ │ └────────────────────────────────────────┘   │ │
│ │ 季節テーマ: [🌸春] [🌻夏] [🍂秋] [❄️冬]      │ │
│ └────────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

### 1.2 状態管理

```dart
// AI補助パネルの状態
class AIAssistantState {
  final bool isExpanded;
  final bool isProcessing;
  final String? selectedText;
  final int cursorPosition;
  final String customInstruction;
  final String currentSeason;
  final List<AISuggestion> suggestions;
  final String? errorMessage;

  const AIAssistantState({
    this.isExpanded = false,
    this.isProcessing = false,
    this.selectedText,
    this.cursorPosition = 0,
    this.customInstruction = '',
    this.currentSeason = 'spring',
    this.suggestions = const [],
    this.errorMessage,
  });
}
```

---

## 2. AI機能ボタン設計

### 2.1 定型機能ボタン

| ボタン | アイコン | 機能説明 | API呼び出し |
|--------|---------|---------|------------|
| **挨拶文生成** | 👋 | 季節に合った挨拶文 | `POST /api/v1/ai/assist` (action: add_greeting) |
| **予定作成** | 📅 | 箇条書き予定リスト | `POST /api/v1/ai/assist` (action: add_schedule) |
| **文章改善** | ✨ | 選択テキスト改善 | `POST /api/v1/ai/assist` (action: rewrite) |
| **見出し生成** | 📝 | 適切な見出し提案 | `POST /api/v1/ai/assist` (action: generate_heading) |
| **要約作成** | 📋 | 長文の要約 | `POST /api/v1/ai/assist` (action: summarize) |
| **詳細展開** | 📖 | 内容を詳しく | `POST /api/v1/ai/assist` (action: expand) |

### 2.2 ボタンコンポーネント

```dart
class AIFunctionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final AIFunctionType functionType;
  final VoidCallback onPressed;
  final bool isProcessing;

  const AIFunctionButton({
    Key? key,
    required this.title,
    required this.icon,
    required this.functionType,
    required this.onPressed,
    this.isProcessing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 80,
      child: ElevatedButton(
        onPressed: isProcessing ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isProcessing)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: 24),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 3. カスタム指示入力

### 3.1 入力フィールド設計

```dart
class CustomInstructionField extends StatefulWidget {
  final String instruction;
  final Function(String) onChanged;
  final VoidCallback onSubmit;
  final bool isProcessing;

  const CustomInstructionField({
    Key? key,
    required this.instruction,
    required this.onChanged,
    required this.onSubmit,
    this.isProcessing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '例：もっと親しみやすい文章にして',
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: onChanged,
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: isProcessing ? null : onSubmit,
            child: isProcessing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('生成'),
          ),
        ],
      ),
    );
  }
}
```

### 3.2 サンプル指示一覧

```dart
final List<String> sampleInstructions = [
  'もっと親しみやすい文章にして',
  '丁寧で正式な表現に変更',
  '短くまとめて',
  '具体例を追加して',
  '保護者向けの説明を追加',
  '子どもたちの様子を詳しく',
];
```

---

## 4. 季節テーマ切り替え

### 4.1 季節テーマボタン

```dart
class SeasonThemeSelector extends StatelessWidget {
  final String currentSeason;
  final Function(String) onSeasonChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSeasonButton('春', '🌸', 'spring'),
        _buildSeasonButton('夏', '🌻', 'summer'),
        _buildSeasonButton('秋', '🍂', 'autumn'),
        _buildSeasonButton('冬', '❄️', 'winter'),
      ],
    );
  }

  Widget _buildSeasonButton(String label, String emoji, String season) {
    final isSelected = currentSeason == season;
    
    return GestureDetector(
      onTap: () => onSeasonChanged(season),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected 
              ? Border.all(color: Colors.blue, width: 2)
              : Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: 20)),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 5. AI結果表示・選択

### 5.1 提案結果UI

```dart
class AISuggestionsPanel extends StatelessWidget {
  final List<AISuggestion> suggestions;
  final Function(AISuggestion) onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI提案結果',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          SizedBox(height: 8),
          ...suggestions.map((suggestion) => _buildSuggestionItem(suggestion)),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(AISuggestion suggestion) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onSuggestionSelected(suggestion),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    '信頼度: ${(suggestion.confidence * 100).toInt()}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Spacer(),
                  Icon(Icons.add_circle_outline, size: 16, color: Colors.blue),
                ],
              ),
              SizedBox(height: 4),
              Text(
                suggestion.text,
                style: TextStyle(fontSize: 14),
              ),
              if (suggestion.explanation.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  suggestion.explanation,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 6. アニメーション・インタラクション

### 6.1 展開/折りたたみアニメーション

```dart
class AIAssistantPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<QuillEditorProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // ヘッダー（常に表示）
            _buildHeader(provider),
            
            // 展開可能コンテンツ
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: provider.isAiAssistVisible ? null : 0,
              child: provider.isAiAssistVisible
                  ? _buildPanelContent(provider)
                  : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(QuillEditorProvider provider) {
    return InkWell(
      onTap: () {
        if (provider.isAiAssistVisible) {
          provider.hideAiAssist();
        } else {
          provider.showAiAssist(selectedText: '', cursorPosition: 0);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'AI補助',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            Spacer(),
            AnimatedRotation(
              turns: provider.isAiAssistVisible ? 0.5 : 0,
              duration: Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 7. 実装ガイド

### 7.1 Provider統合

```dart
// QuillEditorProviderに追加するメソッド
class QuillEditorProvider extends ChangeNotifier {
  // AI補助関連の状態
  String _customInstruction = '';
  List<AISuggestion> _suggestions = [];
  
  // AI機能実行
  Future<void> executeAIFunction(AIFunctionType type) async {
    setProcessing(true);
    
    try {
      final response = await apiService.callAIAssist(
        action: type.apiAction,
        selectedText: _selectedText,
        instruction: _customInstruction,
        context: {
          'document_title': _title,
          'season_theme': _currentSeason,
        },
      );
      
      _suggestions = response.suggestions;
      notifyListeners();
      
    } catch (e) {
      setError('AI処理でエラーが発生しました: $e');
    } finally {
      setProcessing(false);
    }
  }
  
  // 提案を適用
  void applySuggestion(AISuggestion suggestion) {
    if (bridgeService != null) {
      bridgeService!.insertAiContent(
        suggestion.text,
        _cursorPosition,
      );
    }
    
    // 提案パネルをクリア
    _suggestions.clear();
    notifyListeners();
  }
}
```

このAI補助パネル設計により、要件書で求められる直感的で効率的なAI機能統合が実現できます。 