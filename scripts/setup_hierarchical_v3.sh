#!/bin/bash

# 🏗️ 階層型並列AI開発環境セットアップ v3.0
# 参考: https://github.com/kamekamek/Claude-Code-Communication.git
# 構造: COORDINATOR → 3 PARENTs → 9 CHILDs (合計13エージェント)

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# ログ関数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_hierarchy() { echo -e "${PURPLE}[HIERARCHY]${NC} $1"; }

# プロジェクト設定
PROJECT_ROOT=$(pwd)
PROJECT_NAME=$(basename "$PROJECT_ROOT")

# 階層定義
declare -A HIERARCHY_CONFIG=(
    ["coordinator"]="COORDINATOR:プロジェクト統括:main"
    ["parent1"]="PARENT1:Quill.js統合Boss:feat/quill-parent"  
    ["parent2"]="PARENT2:WebView統合Boss:feat/webview-parent"
    ["parent3"]="PARENT3:Gemini API Boss:feat/gemini-parent"
)

# 子エージェント定義
declare -A CHILDREN_CONFIG=(
    ["child1-1"]="CHILD1-1:HTML基本構造Worker:feat/quill-html:parent1"
    ["child1-2"]="CHILD1-2:Quill.js統合Worker:feat/quill-js:parent1"
    ["child1-3"]="CHILD1-3:CSS・スタイルWorker:feat/quill-css:parent1"
    ["child2-1"]="CHILD2-1:WebView実装Worker:feat/webview-impl:parent2"
    ["child2-2"]="CHILD2-2:Bridge通信Worker:feat/webview-bridge:parent2"
    ["child2-3"]="CHILD2-3:統合テストWorker:feat/webview-test:parent2"
    ["child3-1"]="CHILD3-1:API基盤Worker:feat/gemini-api:parent3"
    ["child3-2"]="CHILD3-2:プロンプト管理Worker:feat/gemini-prompt:parent3"
    ["child3-3"]="CHILD3-3:レスポンス処理Worker:feat/gemini-response:parent3"
)

# 依存関係チェック
check_dependencies() {
    log_info "依存関係をチェック中..."
    
    command -v tmux >/dev/null 2>&1 || { log_error "tmux が必要です"; exit 1; }
    command -v git >/dev/null 2>&1 || { log_error "git が必要です"; exit 1; }
    
    if [[ ! -d ".git" ]]; then
        log_error "Gitリポジトリのルートで実行してください"
        exit 1
    fi
    
    log_success "依存関係確認完了"
}

# 既存環境のクリーンアップ
cleanup_existing() {
    log_info "既存環境をクリーンアップ中..."
    
    # Tmuxセッション削除
    for session in coordinator parents workers; do
        if tmux has-session -t "$session" 2>/dev/null; then
            log_warning "Tmuxセッション削除: $session"
            tmux kill-session -t "$session"
        fi
    done
    
    # Git worktreeクリーンアップ
    git worktree prune
    rm -rf ../yutori-coordinator ../yutori-parent* ../yutori-child*
    
    # ログディレクトリ準備
    mkdir -p logs/hierarchy
    rm -f logs/hierarchy/*.log
    
    log_success "クリーンアップ完了"
}

# Git Worktreeセットアップ
setup_worktrees() {
    log_hierarchy "Git Worktreeを階層構築中..."
    
    # Coordinatorワークツリー
    coordinator_path="../yutori-coordinator"
    log_info "Coordinator worktree作成: $coordinator_path"
    git worktree add "$coordinator_path" -b coordinator-main
    
    # Parentワークツリー
    for parent_key in parent1 parent2 parent3; do
        IFS=':' read -r role description branch <<< "${HIERARCHY_CONFIG[$parent_key]}"
        parent_path="../yutori-${parent_key}"
        
        log_info "Parent worktree作成: $role ($parent_path)"
        git worktree add "$parent_path" -b "$branch"
        
        # Parentディレクトリ内に子ワーカー用サブディレクトリ作成
        mkdir -p "$parent_path"/{html,js,css} 2>/dev/null || true  # parent1用
        mkdir -p "$parent_path"/{impl,bridge,test} 2>/dev/null || true  # parent2用  
        mkdir -p "$parent_path"/{api,prompt,response} 2>/dev/null || true  # parent3用
    done
    
    # Childワークツリー
    for child_key in "${!CHILDREN_CONFIG[@]}"; do
        IFS=':' read -r role description branch parent <<< "${CHILDREN_CONFIG[$child_key]}"
        child_path="../yutori-${child_key}"
        
        log_info "Child worktree作成: $role ($child_path)"
        git worktree add "$child_path" -b "$branch"
    done
    
    log_success "全Worktree作成完了"
    git worktree list
}

# Tmux階層セッション作成
setup_tmux_hierarchy() {
    log_hierarchy "Tmux階層セッション構築中..."
    
    # 1. Coordinatorセッション (1ペイン)
    log_info "Coordinatorセッション作成..."
    tmux new-session -d -s coordinator -c "../yutori-coordinator"
    tmux rename-window -t coordinator:0 "coordinator"
    
    # 2. Parentsセッション (3ペイン、横分割)
    log_info "Parentsセッション作成..."
    tmux new-session -d -s parents -c "../yutori-parent1"
    tmux rename-window -t parents:0 "parents"
    
    # Parent1ペイン (Quill.js Boss)
    tmux send-keys -t parents:0 "# PARENT1: Quill.js統合Boss" Enter
    
    # Parent2ペイン追加 (WebView Boss)
    tmux split-window -t parents:0 -h -c "../yutori-parent2"
    tmux send-keys -t parents:0.1 "# PARENT2: WebView統合Boss" Enter
    
    # Parent3ペイン追加 (Gemini Boss)  
    tmux split-window -t parents:0.1 -h -c "../yutori-parent3"
    tmux send-keys -t parents:0.2 "# PARENT3: Gemini API Boss" Enter
    
    # 3. Workersセッション (9ペイン、3x3グリッド)
    log_info "Workersセッション作成..."
    tmux new-session -d -s workers -c "../yutori-child1-1"
    tmux rename-window -t workers:0 "workers"
    
    # 最初の行 (Quill.js Workers)
    tmux send-keys -t workers:0 "# CHILD1-1: HTML基本構造Worker" Enter
    tmux split-window -t workers:0 -h -c "../yutori-child1-2"  # 右に分割
    tmux send-keys -t workers:0.1 "# CHILD1-2: Quill.js統合Worker" Enter
    tmux split-window -t workers:0.1 -h -c "../yutori-child1-3"  # さらに右に分割
    tmux send-keys -t workers:0.2 "# CHILD1-3: CSS・スタイルWorker" Enter
    
    # 2行目追加 (WebView Workers)
    tmux split-window -t workers:0 -v -c "../yutori-child2-1"  # 下に分割
    tmux send-keys -t workers:0.3 "# CHILD2-1: WebView実装Worker" Enter
    tmux split-window -t workers:0.3 -h -c "../yutori-child2-2"  # 右に分割
    tmux send-keys -t workers:0.4 "# CHILD2-2: Bridge通信Worker" Enter
    tmux split-window -t workers:0.4 -h -c "../yutori-child2-3"  # さらに右に分割
    tmux send-keys -t workers:0.5 "# CHILD2-3: 統合テストWorker" Enter
    
    # 3行目追加 (Gemini Workers)
    tmux split-window -t workers:0.3 -v -c "../yutori-child3-1"  # 下に分割
    tmux send-keys -t workers:0.6 "# CHILD3-1: API基盤Worker" Enter
    tmux split-window -t workers:0.6 -h -c "../yutori-child3-2"  # 右に分割
    tmux send-keys -t workers:0.7 "# CHILD3-2: プロンプト管理Worker" Enter
    tmux split-window -t workers:0.7 -h -c "../yutori-child3-3"  # さらに右に分割
    tmux send-keys -t workers:0.8 "# CHILD3-3: レスポンス処理Worker" Enter
    
    log_success "Tmux階層セッション完成"
    log_info "接続コマンド:"
    echo "  tmux attach-session -t coordinator"
    echo "  tmux attach-session -t parents" 
    echo "  tmux attach-session -t workers"
}

# Instructions設定作成
setup_instructions() {
    log_hierarchy "Instructions設定作成中..."
    
    mkdir -p instructions
    
    # Coordinator指示書
    cat > instructions/coordinator.md << 'EOF'
# COORDINATOR 指示書

## 役割
プロジェクト全体の統括責任者として、Phase2タスクを3つの大カテゴリに分解し、各PARENTに指示を送ります。

## タスク分解
**T2-QU-001-A + T2-QU-002-A + T3-AI-002-A** を以下に分解:

### PARENT1向け: Quill.js統合システム (45分)
- HTML基本構造作成
- Quill.js統合スクリプト実装  
- CSS・レスポンシブ対応

### PARENT2向け: WebView統合システム (55分)
- WebView実装
- Bridge通信機能
- 統合テスト

### PARENT3向け: Gemini API システム (50分)
- API基盤実装
- プロンプト管理機能
- レスポンス処理機能

## 実行手順
1. 起動メッセージ確認
2. 各PARENTに分解タスクを送信
3. 進捗監視・調整
4. 完了統合指示

## 通信フォーマット
```
[COORDINATOR→PARENT1] Quill.js統合システム実装開始。HTMLWorker、JSWorker、CSSWorkerに分解実行してください。
```
EOF

    # Parent指示書
    cat > instructions/parent.md << 'EOF'
# PARENT 指示書

## 役割
COORDINATORから受け取ったタスクを3つの細分化タスクに分解し、配下の3つのCHILDに指示します。

## 分解パターン

### PARENT1 (Quill.js Boss)
受信: "Quill.js統合システム実装"
分解→送信:
- CHILD1-1: "T2-QU-001-A1: HTML基本構造作成 (web/quill/index.html)"
- CHILD1-2: "T2-QU-001-A2: Quill.js統合スクリプト実装"  
- CHILD1-3: "T2-QU-001-A3: CSS・レスポンシブ対応"

### PARENT2 (WebView Boss)
受信: "WebView統合システム実装"
分解→送信:
- CHILD2-1: "T2-QU-002-A1: WebView Flutter実装"
- CHILD2-2: "T2-QU-002-A2: Bridge通信機能"
- CHILD2-3: "T2-QU-002-A3: 統合テスト作成"

### PARENT3 (Gemini Boss)
受信: "Gemini APIシステム実装"
分解→送信:
- CHILD3-1: "T3-AI-002-A1: API基盤実装"
- CHILD3-2: "T3-AI-002-A2: プロンプト管理"
- CHILD3-3: "T3-AI-002-A3: レスポンス処理"

## 完了管理
- 全CHILD完了確認
- 統合テスト実行
- COORDINATORへ完了報告

## 通信フォーマット
```
[PARENT1→CHILD1-1] T2-QU-001-A1: HTML基本構造作成を開始してください。
[PARENT1→COORDINATOR] Quill.js統合システム完了しました。
```
EOF

    # Child指示書
    cat > instructions/child.md << 'EOF'
# CHILD WORKER 指示書

## 役割
PARENTから受け取った細分化タスクを TDD で実装し、完了時にPARENTへ報告します。

## 実装フロー
1. **Red Phase**: テスト作成
2. **Green Phase**: 最小実装
3. **Blue Phase**: リファクタリング
4. **報告**: PARENT宛に完了報告

## タスク詳細

### CHILD1-1 (HTML Worker)
- ファイル: `web/quill/index.html`
- 内容: Quill.js用HTML基本構造
- テスト: HTMLバリデーション確認

### CHILD1-2 (JS Worker)  
- ファイル: `web/quill/main.js`
- 内容: Quill.js初期化・設定
- テスト: JS機能テスト

### CHILD1-3 (CSS Worker)
- ファイル: `web/quill/styles.css` 
- 内容: レスポンシブスタイル
- テスト: CSS適用確認

### CHILD2-1 (WebView Worker)
- ファイル: `lib/features/editor/webview_editor.dart`
- 内容: WebView Flutter実装
- テスト: WebView表示テスト

### CHILD2-2 (Bridge Worker)
- ファイル: `lib/features/editor/js_bridge.dart`
- 内容: Flutter↔JS通信
- テスト: Bridge通信テスト

### CHILD2-3 (Test Worker)  
- ファイル: `test/features/editor/`
- 内容: 統合テスト作成
- テスト: E2Eテスト実行

### CHILD3-1 (API Worker)
- ファイル: `backend/functions/services/gemini_client.py`
- 内容: Gemini API基盤
- テスト: API接続テスト

### CHILD3-2 (Prompt Worker)
- ファイル: `backend/functions/services/prompt_manager.py`
- 内容: プロンプト管理
- テスト: プロンプト生成テスト

### CHILD3-3 (Response Worker)
- ファイル: `backend/functions/services/response_parser.py`
- 内容: レスポンス処理
- テスト: パース処理テスト

## 完了報告フォーマット
```
[CHILD1-1→PARENT1] T2-QU-001-A1: HTML基本構造作成完了。web/quill/index.html 実装済み。テスト通過。
```
EOF

    log_success "Instructions設定完了"
}

# Claude設定作成
setup_claude_configs() {
    log_hierarchy "Claude設定作成中..."
    
    # Coordinator用CLAUDE.md
    cat > ../yutori-coordinator/CLAUDE.md << 'EOF'
# COORDINATOR: プロジェクト統括責任者

## 役割
Phase2並列開発の統括責任者として、大タスクを分解してPARENTに指示し、全体の進捗を管理します。

## 指示内容
instructions/coordinator.md に詳細な指示があります。

## 実行コマンド
```bash
# 他エージェントに指示送信
../scripts/agent_hierarchy_communication.sh PARENT1 "Quill.js統合システム実装開始"
../scripts/agent_hierarchy_communication.sh PARENT2 "WebView統合システム実装開始"  
../scripts/agent_hierarchy_communication.sh PARENT3 "Gemini APIシステム実装開始"

# 進捗確認
../scripts/monitor_hierarchy.sh
```

## 重要事項
- タスク分解の責任者
- 進捗統合管理
- 最終品質確認
EOF

    # Parent用CLAUDE.md作成
    for parent_id in 1 2 3; do
        cat > "../yutori-parent${parent_id}/CLAUDE.md" << EOF
# PARENT${parent_id}: チームリーダー

## 役割
COORDINATORから受け取ったタスクを細分化し、配下の3つのCHILDに指示・管理します。

## 指示内容
instructions/parent.md に詳細な指示があります。

## 実行コマンド
\`\`\`bash
# 子エージェントに指示送信
../scripts/agent_hierarchy_communication.sh CHILD${parent_id}-1 "細分化タスク1開始"
../scripts/agent_hierarchy_communication.sh CHILD${parent_id}-2 "細分化タスク2開始"
../scripts/agent_hierarchy_communication.sh CHILD${parent_id}-3 "細分化タスク3開始"

# 進捗確認
../scripts/monitor_hierarchy.sh
\`\`\`

## 重要事項
- タスク細分化の責任者
- 配下CHILD管理
- 統合テスト実行
EOF
    done
    
    # Child用CLAUDE.md作成
    for child_key in "${!CHILDREN_CONFIG[@]}"; do
        IFS=':' read -r role description branch parent <<< "${CHILDREN_CONFIG[$child_key]}"
        
        cat > "../yutori-${child_key}/CLAUDE.md" << EOF
# $role

## 役割
$description を TDD で実装します。

## 指示内容
instructions/child.md に詳細な指示があります。

## TDD実装フロー
1. **Red**: テスト作成
2. **Green**: 最小実装  
3. **Blue**: リファクタリング
4. **報告**: PARENT宛完了報告

## 実行コマンド
\`\`\`bash
# テスト実行
flutter test  # または python -m pytest

# 完了報告
../scripts/agent_hierarchy_communication.sh ${parent^^} "$role 作業完了"
\`\`\`
EOF
    done
    
    log_success "Claude設定完了"
}

# メイン実行
main() {
    log_hierarchy "🏗️ 階層型並列AI開発環境 v3.0 セットアップ開始"
    
    check_dependencies
    cleanup_existing
    setup_worktrees
    setup_tmux_hierarchy
    setup_instructions
    setup_claude_configs
    
    log_success "🎉 階層型環境セットアップ完了！"
    
    echo ""
    log_hierarchy "📋 接続方法:"
    echo "1. tmux attach-session -t coordinator   # 統括者"
    echo "2. tmux attach-session -t parents       # 3ボス"
    echo "3. tmux attach-session -t workers       # 9ワーカー"
    echo ""
    
    log_hierarchy "🚀 次のステップ:"
    echo "1. 各セッションでClaude Code起動"  
    echo "2. COORDINATORから指示開始"
    echo "3. 階層通信で並列実行"
    echo ""
    
    log_warning "⚠️ 13エージェントの協調動作システムです。慎重に進めてください。"
}

# 実行
main "$@" 