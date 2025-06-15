# 🚀 ClaudeCode組織システム 5分クイックスタート

## 📌 このガイドについて

ClaudeCodeの組織システムを**5分で**セットアップして実際に動かすための実践的ガイドです。複雑な理論は後回しにして、まずは動かしてみましょう！

## ⏱️ 5分でできること

- ✅ 基本環境の構築（2分）
- ✅ エージェント起動（2分）
- ✅ 実際のプロジェクト実行（1分）

## 🛠️ 必要なもの

```bash
# 必須ツール（事前にインストール）
- tmux
- Claude Code CLI
- bash

# Mac の場合
brew install tmux

# Claude Code CLI は事前にセットアップ済みと仮定
```

## 📁 Step 1: プロジェクト作成（30秒）

```bash
# 1. プロジェクトディレクトリ作成
mkdir my-ai-team
cd my-ai-team

# 2. 必要ディレクトリ作成
mkdir -p instructions tmp logs
```

## 🔧 Step 2: 基本ファイル作成（90秒）

### setup.sh を作成
```bash
cat > setup.sh << 'EOF'
#!/bin/bash
set -e

echo "🤖 AI Team Setup"
echo "================"

# 既存セッションクリーンアップ
tmux kill-session -t multiagent 2>/dev/null || true
tmux kill-session -t president 2>/dev/null || true

# multiagentセッション作成（4ペイン）
tmux new-session -d -s multiagent -n "agents"
tmux split-window -h -t "multiagent:0"
tmux select-pane -t "multiagent:0.0"
tmux split-window -v
tmux select-pane -t "multiagent:0.2"
tmux split-window -v

# ペインタイトル設定
PANE_TITLES=("boss1" "worker1" "worker2" "worker3")
for i in {0..3}; do
    tmux select-pane -t "multiagent:0.$i" -T "${PANE_TITLES[$i]}"
    tmux send-keys -t "multiagent:0.$i" "cd $(pwd)" C-m
    tmux send-keys -t "multiagent:0.$i" "echo '=== ${PANE_TITLES[$i]} エージェント ==='" C-m
done

# presidentセッション作成
tmux new-session -d -s president
tmux send-keys -t president "cd $(pwd)" C-m
tmux send-keys -t president "echo '=== PRESIDENT セッション ==='" C-m

echo "✅ Setup完了！"
echo "次: tmux attach-session -t president"
EOF

chmod +x setup.sh
```

### agent-send.sh を作成
```bash
cat > agent-send.sh << 'EOF'
#!/bin/bash

get_agent_target() {
    case "$1" in
        "president") echo "president" ;;
        "boss1") echo "multiagent:0.0" ;;
        "worker1") echo "multiagent:0.1" ;;
        "worker2") echo "multiagent:0.2" ;;
        "worker3") echo "multiagent:0.3" ;;
        *) echo "" ;;
    esac
}

send_message() {
    local target="$1"
    local message="$2"
    
    echo "📤 送信: $target ← '$message'"
    tmux send-keys -t "$target" C-c
    sleep 0.3
    tmux send-keys -t "$target" "$message"
    tmux send-keys -t "$target" C-m
    sleep 0.5
}

main() {
    if [[ $# -lt 2 ]]; then
        echo "使用方法: $0 [エージェント名] [メッセージ]"
        exit 1
    fi
    
    local agent_name="$1"
    local message="$2"
    local target=$(get_agent_target "$agent_name")
    
    if [[ -z "$target" ]]; then
        echo "❌ エラー: 不明なエージェント '$agent_name'"
        exit 1
    fi
    
    send_message "$target" "$message"
    echo "✅ 送信完了: $agent_name"
}

main "$@"
EOF

chmod +x agent-send.sh
```

## 📋 Step 3: 最小限の指示書作成（60秒）

### PRESIDENT指示書
```bash
cat > instructions/president.md << 'EOF'
# あなたの役割：PRESIDENT

## 基本動作
1. ユーザーの要求を深く理解
2. boss1に明確な指示を送信
3. 成果を確認して改善指示

## 指示テンプレート
```bash
./agent-send.sh boss1 "あなたはboss1です。

【プロジェクト名】[プロジェクト名]
【ビジョン】[理想の状態]
【成功基準】[測定可能な指標]

革新的なソリューションを創出してください。"
```

## 重要なポイント
- ユーザーニーズを100%満たすまで継続
- 明確なビジョンと成功基準を提示
EOF
```

### boss1指示書
```bash
cat > instructions/boss.md << 'EOF'
# あなたの役割：boss1

## 基本動作
1. presidentからの指示を理解
2. 各workerに創造的チャレンジを送信
3. 成果を統合してpresidentに報告

## worker指示テンプレート
```bash
./agent-send.sh worker1 "あなたはworker1です。

【プロジェクト】[プロジェクト名]
【チャレンジ】革新的なアイデアを3つ以上提案してください。

【フォーマット】
1. アイデア名：[名前]
   概要：[説明]
   革新性：[何が新しいか]

完了したら報告してください。"
```

## 重要なポイント
- 各workerに「革新的アイデア3つ以上」を要求
- 天才的な統合力で成果をまとめる
EOF
```

### worker指示書
```bash
cat > instructions/worker.md << 'EOF'
# あなたの役割：worker

## 基本動作
1. boss1からの指示を理解
2. やることリストを作成
3. タスクを実行
4. 成果を報告

## 実行フロー
```markdown
## やることリスト
- [ ] 要求分析
- [ ] アイデア創出
- [ ] 実装
- [ ] 報告書作成
```

## 報告テンプレート
```bash
./agent-send.sh boss1 "【Worker完了報告】

## 実施したタスク
[完了したタスク]

## 創出した価値
1. [成果1]
2. [成果2]
3. [成果3]

## 革新的な要素
[何が新しいか]"
```

## 重要なポイント
- 専門性を活かした革新的実装
- 構造化された報告
EOF
```

## 🚀 Step 4: システム起動（60秒）

```bash
# 1. 環境構築
./setup.sh

# 2. PRESIDENTセッションに接続
tmux attach-session -t president
```

**PRESIDENT画面で：**
```bash
# Claude起動
claude --dangerously-skip-permissions
```

**新しいターミナルを開いて：**
```bash
# 他のエージェント一括起動
for i in {0..3}; do 
  tmux send-keys -t multiagent:0.$i 'claude --dangerously-skip-permissions' C-m
done

# multiagent画面確認
tmux attach-session -t multiagent
```

## 🎯 Step 5: 実際に動かしてみる（30秒）

**PRESIDENT画面に戻って以下を入力：**

```
あなたはpresidentです。

おしゃれなToDoアプリを作成してください。
- シンプルで使いやすい
- モダンなデザイン
- 完全に動作する

指示書に従って実行してください。
```

## 🎉 完了！

これで基本的なClaudeCode組織システムが動作します！

### 何が起こるか
1. **PRESIDENT**がプロジェクトを分析
2. **boss1**が各workerに創造的チャレンジを送信
3. **worker1,2,3**が並列で作業
4. **boss1**が成果を統合
5. **PRESIDENT**に最終報告

## 📊 動作確認方法

### セッション確認
```bash
# セッション一覧
tmux ls

# 各セッションに接続
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

## 🔧 トラブルシューティング

### よくある問題

#### 1. セッションが見つからない
```bash
# 解決方法
./setup.sh  # 再実行
```

#### 2. エージェントが反応しない
```bash
# 各ペインでClaude再起動
tmux send-keys -t multiagent:0.0 'claude --dangerously-skip-permissions' C-m
```

#### 3. メッセージが届かない
```bash
# 手動テスト
./agent-send.sh boss1 "テストメッセージ"
```

## 📈 次のステップ

### 1. カスタマイズ
- 専門分野の調整
- 指示書の詳細化
- フォーマットの改良

### 2. 高度な機能
- 進捗管理の自動化
- 外部ツール連携
- メトリクス収集

### 3. スケールアップ
- worker数の増加
- 複数プロジェクト並行
- 部門制の導入

## 💡 成功のコツ

### 1. 明確な指示
```bash
# 良い例
./agent-send.sh boss1 "あなたはboss1です。

【プロジェクト名】ToDoアプリ開発
【ビジョン】誰でも直感的に使えるタスク管理ツール
【成功基準】
- 3クリックでタスク追加
- 美しいUI
- 完全動作

革新的なアイデアで実現してください。"

# 悪い例
./agent-send.sh boss1 "ToDoアプリ作って"
```

### 2. 継続的改善
```bash
# 不足がある場合
./agent-send.sh boss1 "【追加作業依頼】

前回の成果を確認しました。以下の改善をお願いします：

## 改善点
- UIの美しさが不足
- レスポンシブ対応が必要

ユーザーニーズを100%満たすまで継続してください。"
```

### 3. 創造性の促進
- 「革新的アイデア3つ以上」を必ず要求
- 既存の枠にとらわれない思考を促進
- 失敗を恐れない環境作り

## 🎯 実際の成果例

### EmotiFlowアンケートシステム（3時間で完成）
- 😊 絵文字で感情表現
- 📊 リアルタイム結果表示
- 📱 完全レスポンシブ
- 🧪 100%テストカバレッジ

### 革新的アイデア12個生成
- AIコンシェルジュ機能
- WebXR体験
- 量子暗号化セキュリティ
- ブロックチェーン品質保証

## 📚 さらに詳しく学ぶ

- `claude-code-organization-guide.md`: 完全な理論と実装
- `ai-context-template.md`: 詳細なコンテキストテンプレート
- `instructions/`: 各エージェントの詳細指示書

## 🎉 まとめ

このクイックスタートガイドで、ClaudeCodeの組織システムの基本を体験できました。重要なのは：

1. **明確な役割分担**
2. **構造化されたコミュニケーション**
3. **創造性の促進**
4. **継続的改善**

これらの原則を守ることで、単一AIでは不可能な組織的創造性と効率性を実現できます。

**今すぐ始めて、AIチームの力を体験してください！** 🚀 