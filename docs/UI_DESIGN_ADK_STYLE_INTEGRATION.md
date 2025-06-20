# 🎨 ADKマルチエージェント + スタイル統合 UI設計（修正版）

**作成日**: 2025年6月19日  
**方針**: 音声入力直後のスタイル選択（クラシック/モダン）を保持し、ADKエージェントとの統合  

## 📋 プロンプト構造の理解

### 現在のプロンプトファイル構成
```
prompts/
├── CLASSIC_TENSAKU.md   - クラシック: 音声→JSON変換
├── CLASSIC_LAYOUT.md    - クラシック: JSON→HTML変換
├── MODERN_TENSAKU.md    - モダン: 音声→JSON変換
└── MODERN_LAYOUT.md     - モダン: JSON→HTML変換
```

### ADKエージェントとプロンプトの対応
```
選択されたスタイル
    ↓
[1] 文章生成エージェント → CLASSIC_TENSAKU.md OR MODERN_TENSAKU.md
[2] デザイン仕様エージェント → 自動でスタイル対応
[3] HTML生成エージェント → CLASSIC_LAYOUT.md OR MODERN_LAYOUT.md
[4] PDF・画像・配信エージェント → スタイル継承
```

## 🔄 修正されたUIフロー

### **Step 1: 音声入力（従来通り）**
```
┌─────────────────────────────────────┐
│ 🎤 音声入力                         │
├─────────────────────────────────────┤
│                                     │
│     [🔴 録音中...]                  │
│                                     │
│ "今日は運動会の練習をしました..."    │
│                                     │
└─────────────────────────────────────┘
```

### **Step 2: スタイル選択（従来通り・重要！）**
```
┌─────────────────────────────────────┐
│ 🎨 スタイル選択                     │
├─────────────────────────────────────┤
│                                     │
│  📋 学級通信のスタイルを選択:       │
│                                     │
│  ○ クラシック                      │
│    └─ 伝統的で読みやすい           │
│                                     │
│  ○ モダン                          │
│    └─ インフォグラフィック的       │
│                                     │
│  [学級通信を作成する]               │
│                                     │
└─────────────────────────────────────┘
```

### **Step 3: ADKエージェント進捗（新規）**
スタイル選択後、エージェントがそれぞれ対応プロンプトを使用：

```
┌─────────────────────────────────────────────┐
│ 🎯 学級通信生成プロセス                      │
│ 選択スタイル: 📋 クラシック                 │
├─────────────────────────────────────────────┤
│                                             │
│ [1] 📝 文章生成エージェント      ✅ 完了    │
│     └─ CLASSIC_TENSAKU.md 使用             │
│     └─ 850文字の学級通信を生成             │
│                                             │
│ [2] 🎨 デザイン仕様エージェント  🔄 処理中  │
│     └─ クラシック仕様でデザイン作成中       │
│                                             │
│ [3] 🏗️ HTML生成エージェント     ⏳ 待機中  │
│     └─ CLASSIC_LAYOUT.md で実行予定        │
│                                             │
│ [4] 📄 PDF変換エージェント      ⏳ 待機中  │
│     └─ クラシックスタイル継承               │
│                                             │
│ [5] 🖼️ 画像・メディアエージェント ⏳ 待機中 │
│                                             │
│ [6] 📤 配信準備エージェント     ⏳ 待機中  │
│                                             │
│ [7] ✅ 品質保証エージェント     ⏳ 待機中  │
│                                             │
└─────────────────────────────────────────────┘
```

### **Step 4: インタラクティブ編集（新規）**
```
┌─────────────────────────────────────┐
│ 📝 内容編集 (クラシックスタイル)    │
├─────────────────────────────────────┤
│ ┌─────────────┬─────────────────┐ │
│ │ テキスト     │ プレビュー       │ │
│ ├─────────────┼─────────────────┤ │
│ │             │                 │ │
│ │ [編集可能    │ [クラシック     │ │
│ │  テキスト]   │  レイアウト     │ │
│ │             │  プレビュー]    │ │
│ │             │                 │ │
│ └─────────────┴─────────────────┘ │
│                                     │
│ 🔧 編集ツール:                      │
│ [見出し] [強調] [🤖AI改善]         │
│                                     │
└─────────────────────────────────────┘
```

## 🎨 スタイル別のビジュアル差分

### クラシックスタイル選択時
```
🎨 エージェントカラー（落ち着いた色調）
├── 文章生成: #2E7D32 (深緑)
├── デザイン: #1976D2 (深青)  
├── HTML: #F57C00 (深橙)
└── その他: 落ち着いたトーン

📋 プロンプト使用:
├── CLASSIC_TENSAKU.md → 伝統的で信頼性重視
└── CLASSIC_LAYOUT.md → シングルカラム・読みやすさ重視
```

### モダンスタイル選択時
```
🎨 エージェントカラー（鮮やかな色調）
├── 文章生成: #4CAF50 (鮮緑)
├── デザイン: #2196F3 (鮮青)
├── HTML: #FF9800 (鮮橙)  
└── その他: ビビッドトーン

📋 プロンプト使用:
├── MODERN_TENSAKU.md → インフォグラフィック的
└── MODERN_LAYOUT.md → 視覚的美しさ重視
```

## 💻 実装修正案

### 1. エージェントダッシュボードの修正
```dart
class ADKAgentDashboard extends StatefulWidget {
  final List<AgentStatus> agentStatuses;
  final NewsletterStyle selectedStyle; // 🆕 追加
  final Function(String agentId)? onAgentTap;
  
  // スタイル表示を追加
  Widget _buildStyleIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selectedStyle == NewsletterStyle.classic 
            ? Colors.blue.shade50 
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selectedStyle == NewsletterStyle.classic 
                ? Icons.article 
                : Icons.auto_awesome,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            selectedStyle == NewsletterStyle.classic 
                ? 'クラシック' 
                : 'モダン',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

enum NewsletterStyle { classic, modern }
```

### 2. エージェント設定にスタイル対応
```dart
class ADKAgentConfigs {
  static List<AgentStatus> getAgentsForStyle(NewsletterStyle style) {
    final baseColor = style == NewsletterStyle.classic 
        ? Colors.blue.shade700 
        : Colors.orange.shade600;
    
    return [
      AgentStatus(
        id: 'content_writer',
        name: '文章生成エージェント', 
        message: style == NewsletterStyle.classic
            ? 'CLASSIC_TENSAKU.md 使用'
            : 'MODERN_TENSAKU.md 使用',
        color: baseColor,
      ),
      AgentStatus(
        id: 'html_generator',
        name: 'HTML生成エージェント',
        message: style == NewsletterStyle.classic
            ? 'CLASSIC_LAYOUT.md で実行予定' 
            : 'MODERN_LAYOUT.md で実行予定',
        color: baseColor,
      ),
      // ... 他のエージェント
    ];
  }
}
```

### 3. バックエンド統合
```python
# adk_enhanced_service.py の修正
def _initialize_enhanced_adk_agents(self, style: str = "classic"):
    """スタイルに応じたエージェント初期化"""
    
    # プロンプト選択
    content_prompt = load_prompt("classic" if style == "classic" else "modern")
    layout_prompt_file = "CLASSIC_LAYOUT.md" if style == "classic" else "MODERN_LAYOUT.md"
    
    # コンテンツ生成エージェント
    content_agent = LlmAgent(
        name="content_writer_agent",
        instruction=f"""
        {content_prompt}
        
        スタイル: {style}
        重視ポイント: {"伝統的で読みやすい" if style == "classic" else "インフォグラフィック的"}
        """,
        tools=[FunctionTool(self._newsletter_content_generator_tool)]
    )
    
    # HTML生成エージェント  
    html_agent = LlmAgent(
        name="html_generator_agent",
        instruction=f"""
        {layout_prompt_file}の指示に従って、{style}スタイルでHTMLを生成してください。
        """,
        tools=[FunctionTool(self._html_generator_tool)]
    )
```

## 🎯 UIフロー改善点まとめ

### ✅ **保持される要素（重要）**
1. **音声入力直後のスタイル選択** - 既存UXを維持
2. **クラシック・モダンの2択** - 既存プロンプトを完全活用
3. **使い慣れたワークフロー** - 教師の学習コストを最小化

### 🆕 **追加される要素**
1. **エージェント進捗の可視化** - 選択したスタイルが反映されることを確認
2. **プロンプト使用状況の表示** - どのプロンプトが使われているか明示
3. **スタイル一貫性** - 全エージェントで選択スタイルを継承

### 🔧 **改善される要素**
1. **透明性** - どのプロンプトが使われているか見える
2. **安心感** - 選択したスタイルが確実に反映される
3. **一貫性** - PDF・画像・配信まで一貫したスタイル

## 🚀 実装優先度

### Phase 1（必須）
1. スタイル選択UI保持
2. エージェント進捗でスタイル表示
3. プロンプト使用状況の明示

### Phase 2（推奨）  
4. スタイル別カラーテーマ
5. インタラクティブ編集でスタイル継承

### Phase 3（オプション）
6. スタイル別テンプレート
7. スタイル切り替え機能

## 💡 期待される効果

### **既存ユーザーへの配慮**
- **学習コスト0**: 従来の操作感覚のまま使用可能
- **安心感**: 慣れ親しんだスタイル選択が継続
- **信頼性**: 既存プロンプトを100%活用

### **新機能によるメリット**
- **透明性**: エージェントがどのプロンプトを使用しているか明確
- **一貫性**: 全プロセスでスタイルが統一される  
- **品質**: マルチエージェントによる段階的な品質向上

この設計により、**既存の優れたプロンプトシステム**と**新しいADKマルチエージェント**が完璧に統合され、教師にとって使いやすく、かつ高品質な学級通信作成が実現されます！