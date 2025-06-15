# ClaudeCode 組織システム

## システム概要

このプロジェクトは複数のClaudeエージェントが協力して働く組織システムです。

## エージェント構成
- **PRESIDENT**: プロジェクト統括責任者
- **boss1**: チームリーダー・ファシリテーター  
- **worker1**: フロントエンド/UI専門
- **worker2**: バックエンド/データ専門
- **worker3**: インフラ/テスト専門

## 基本フロー
PRESIDENT → boss1 → workers → boss1 → PRESIDENT

## 使用方法

### 1. 環境構築
```bash
./setup.sh
```

### 2. エージェント起動
```bash
# PRESIDENTセッション
tmux attach-session -t president

# 他のエージェント
tmux attach-session -t multiagent
```

### 3. Claude起動（各ペインで）
```bash
claude --dangerously-skip-permissions
```

### 4. コミュニケーション
```bash
./agent-send.sh [相手] "[メッセージ]"
```

## 指示書参照
各エージェントは以下を参照：
- `@instructions/president.md` (PRESIDENT用)
- `@instructions/boss.md` (boss1用)  
- `@instructions/worker.md` (worker用)
- `@CLAUDE.md` (このファイル)

## 重要なポイント
- 各エージェントの専門性を活用
- 革新的アイデア3つ以上の創出
- 構造化されたコミュニケーション
- ユーザーニーズ100%充足まで継続