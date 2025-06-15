# 🤖 ClaudeCode組織システム

複数のClaudeエージェントが協力して働く組織システムです。

## 🚀 クイックスタート

### 1. 環境構築（30秒）
```bash
cd claude_org
./setup.sh
```

### 2. エージェント起動（60秒）
```bash
# PRESIDENTセッション起動
tmux attach-session -t president
# 各ペインでClaude起動: claude --dangerously-skip-permissions

# 別ターミナルで他のエージェント起動
for i in {0..3}; do 
  tmux send-keys -t multiagent:0.$i 'claude --dangerously-skip-permissions' C-m
done

# multiagent画面確認
tmux attach-session -t multiagent
```

### 3. 実際に動かす（30秒）
PRESIDENT画面で以下を入力：

```
あなたはpresidentです。

おしゃれなToDoアプリを作成してください。
- シンプルで使いやすい
- モダンなデザイン
- 完全に動作する

指示書に従って実行してください。
```

## 📁 ファイル構成

```
claude_org/
├── setup.sh              # 環境構築スクリプト
├── agent-send.sh          # メッセージ送信スクリプト
├── CLAUDE.md             # システム設定
├── instructions/         # 役割別指示書
│   ├── president.md      # PRESIDENT用
│   ├── boss.md          # boss1用
│   └── worker.md        # worker用
├── logs/                # コミュニケーション履歴
└── tmp/                 # 一時ファイル
```

## 🎯 エージェント構成

- **PRESIDENT**: プロジェクト統括責任者
- **boss1**: チームリーダー・ファシリテーター
- **worker1**: フロントエンド/UI専門
- **worker2**: バックエンド/データ専門  
- **worker3**: インフラ/テスト専門

## 💡 基本フロー

1. **PRESIDENT**がユーザー要求を深層分析
2. **boss1**が各workerに創造的チャレンジを送信
3. **worker1,2,3**が並列で革新的アイデアを創出・実装
4. **boss1**が成果を統合・昇華
5. **PRESIDENT**が最終確認・継続改善指示

## 🔧 使用方法

### メッセージ送信
```bash
./agent-send.sh [相手] "[メッセージ]"
```

### セッション管理
```bash
# セッション確認
tmux ls

# セッション接続
tmux attach-session -t president
tmux attach-session -t multiagent
```

### ログ確認
```bash
# コミュニケーションログ
cat logs/send_log.txt

# 進捗ファイル
ls tmp/
```

## 🎉 期待される成果

- **革新的アイデア**: 各workerから3つ以上の創造的提案
- **並列処理**: 複数の専門分野で同時作業
- **品質保証**: 段階的な確認とフィードバック
- **継続改善**: ユーザーニーズ100%充足まで繰り返し

## ⚠️ 重要なポイント

1. **明確な役割分担**: 各エージェントの専門性を活用
2. **構造化コミュニケーション**: 定型フォーマットで効率化
3. **創造性促進**: 「革新的アイデア3つ以上」を必須要求
4. **品質管理**: PRESIDENT による継続的な改善指示

---

**今すぐ始めて、AIチームの力を体験してください！** 🚀