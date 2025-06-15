#!/bin/bash
# 並列開発環境セットアップ v2.0 (Claude-Code-Communication手法統合)

set -e

PROJECT_ROOT="/Users/kamenonagare/yutorikyoshitu"
PROJECT_NAME="yutorikyoshitu"
SESSION_NAME="yutori-parallel"

# ログ関数
log_info() { echo "ℹ️  $1"; }
log_success() { echo "✅ $1"; }
log_warning() { echo "⚠️  $1"; }

echo "🚀 Phase 2並列開発環境セットアップ v2.0"
echo "========================================"

# タスク定義（依存関係を考慮した順序）
TASKS=(
    "quill-html:T2-QU-001-A:Quill.js HTMLファイル作成:feat/quill-html-base:45:PRIORITY"
    "gemini-api:T3-AI-002-A:Gemini API基盤実装:feat/gemini-api-client:50:PARALLEL"
    "webview-integration:T2-QU-002-A:WebView Flutter統合:feat/webview-integration:55:DEPENDENT"
)

# 既存環境の確実なクリーンアップ
cleanup_existing_environment() {
    log_info "既存環境クリーンアップ中..."
    
    # Tmuxセッション削除
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        log_warning "既存セッション削除: $SESSION_NAME"
        tmux kill-session -t "$SESSION_NAME"
    fi
    
    # 既存worktree削除
    git worktree list | grep -E "(quill-html|webview-integration|gemini-api)" | while read path hash branch; do
        if [[ -d "$path" ]]; then
            log_warning "既存worktree削除: $path"
            rm -rf "$path"
        fi
    done
    
    git worktree prune
    log_success "クリーンアップ完了"
}

# Git worktree作成（改良版）
create_enhanced_worktrees() {
    log_info "強化版Git Worktree作成中..."
    
    for task_def in "${TASKS[@]}"; do
        IFS=':' read -r task_key task_id description branch_name duration priority <<< "$task_def"
        
        worktree_path="../${PROJECT_NAME}-${task_key}"
        
        # ブランチ作成
        if git show-ref --verify --quiet refs/heads/"$branch_name"; then
            log_warning "既存ブランチ削除: $branch_name"
            git branch -D "$branch_name" 2>/dev/null || true
        fi
        
        # worktree作成
        log_info "Worktree作成: $task_id ($description)"
        git worktree add "$worktree_path" -b "$branch_name"
        
        # 専用CLAUDE.md作成
        create_specialized_claude_config "$worktree_path" "$task_key" "$task_id" "$description" "$priority"
        
        log_success "Worktree完成: $worktree_path"
    done
    
    log_success "全Worktree作成完了"
    git worktree list
}

# 専門化されたCLAUDE.md作成
create_specialized_claude_config() {
    local worktree_path=$1
    local task_key=$2
    local task_id=$3
    local description=$4
    local priority=$5
    
    local claude_md="$worktree_path/CLAUDE.md"
    
    cat > "$claude_md" << EOF
# $task_id: $description

## 🎯 エージェント設定
- **エージェント名**: ${task_key}-agent
- **担当タスク**: $task_id
- **優先度**: $priority
- **作業ディレクトリ**: $worktree_path

## 🔥 実行指示
**あなたは${task_key}-agentです。以下の指示に従ってください：**

### 📋 タスク詳細
$description を担当します。

### 🎯 完了条件
docs/tasks.md の $task_id セクションで詳細な完了条件を確認してください。

### 🔴🟢🔵 TDD実装フロー
1. **Red Phase**: テストを先に作成（失敗させる）
2. **Green Phase**: 最小限の実装でテスト通過
3. **Blue Phase**: リファクタリングで品質向上

### 📝 進捗報告
- 各フェーズ完了時にコミット
- 最終完了時に docs/tasks.md のチェックボックス更新
- Git pushで他エージェントに進捗通知

### 🤝 エージェント間連携
EOF

    # タスク別の専門指示を追加
    case $task_key in
        "quill-html")
            cat >> "$claude_md" << 'EOF'

## 📋 Quill.js HTML専門指示

### 🎯 成果物
- `web/quill/index.html`: Quill.jsエディタのHTMLファイル
- 基本ツールバー設定
- 日本語フォント対応
- 季節カラーパレット準備

### 🔗 依存関係
- このタスク完了後、webview-integrationエージェントが開始可能
- 完了時は他エージェントに通知してください

### 📚 参考資料
- docs/22_SPEC_quill_features.md
- docs/23_SPEC_quill_implementation.md
EOF
            ;;
        "webview-integration")
            cat >> "$claude_md" << 'EOF'

## 📋 WebView統合専門指示

### ⚠️ 依存関係
**重要**: quill-html-agentのT2-QU-001-A完了を必ず待ってください

### 🎯 成果物
- Flutter WebViewウィジェット実装
- JavaScript Bridge通信
- Quill.js連携確認

### 📚 参考資料
- docs/23_SPEC_quill_implementation.md Section 2-3
EOF
            ;;
        "gemini-api")
            cat >> "$claude_md" << 'EOF'

## 📋 Gemini API専門指示

### 🎯 成果物
- `backend/functions/services/gemini_client.py`
- 基本API接続テスト
- エラーハンドリング実装

### 🔑 設定情報
- Vertex AI設定確認
- 認証情報確認

### 📚 参考資料  
- docs/30_API_endpoints.md Section 3.1
- docs/21_SPEC_ai_prompts.md
EOF
            ;;
    esac
    
    cat >> "$claude_md" << 'EOF'

## 🚀 実行開始
タスクを開始してください！進捗は定期的に報告してください。
EOF
}

# 改良版Tmuxセッション作成
create_enhanced_tmux_session() {
    log_info "改良版Tmuxセッション作成中..."
    
    # メインセッション作成
    tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_ROOT"
    tmux rename-window -t "$SESSION_NAME:0" "control"
    
    # コントロールパネル設定
    tmux send-keys -t "$SESSION_NAME:control" "clear" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo '🎛️  Phase 2並列開発コントロールパネル'" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo '======================================'" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo ''" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo '📊 監視ダッシュボード: ./scripts/monitor_integration.sh'" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo '🤖 エージェント通信: ./scripts/agent_communication.sh'" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo '🚀 Claude起動: ./scripts/start_claude_sequential.sh'" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo ''" Enter
    
    # 各エージェント用ウィンドウ作成
    local window_index=1
    for task_def in "${TASKS[@]}"; do
        IFS=':' read -r task_key task_id description branch_name duration priority <<< "$task_def"
        
        worktree_path="../${PROJECT_NAME}-${task_key}"
        window_name="${task_key}-agent"
        
        # ウィンドウ作成
        tmux new-window -t "$SESSION_NAME:$window_index" -c "$worktree_path" -n "$window_name"
        
        # 3ペイン構成（上：Claude Code、左下：開発、右下：ログ）
        tmux split-window -t "$SESSION_NAME:$window_name" -v -c "$worktree_path"
        tmux split-window -t "$SESSION_NAME:$window_name.1" -h -c "$worktree_path"
        
        # 上ペイン：Claude Code用
        tmux send-keys -t "$SESSION_NAME:$window_name.0" "clear" Enter
        tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo '🤖 $task_id: $description'" Enter
        tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo '優先度: $priority | ディレクトリ: $worktree_path'" Enter
        tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo ''" Enter
        tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo '📋 Claude Code起動準備完了 - claude コマンドで開始'" Enter
        
        # 左下ペイン：開発用
        tmux send-keys -t "$SESSION_NAME:$window_name.1" "clear" Enter
        tmux send-keys -t "$SESSION_NAME:$window_name.1" "echo '⚙️  開発・テスト実行ペイン'" Enter
        
        # 右下ペイン：ログ監視用
        tmux send-keys -t "$SESSION_NAME:$window_name.2" "clear" Enter
        tmux send-keys -t "$SESSION_NAME:$window_name.2" "echo '📊 Git & 進捗ログ'" Enter
        tmux send-keys -t "$SESSION_NAME:$window_name.2" "git status" Enter
        
        ((window_index++))
    done
    
    # コントロールウィンドウに戻る
    tmux select-window -t "$SESSION_NAME:0"
    
    log_success "改良版Tmuxセッション '$SESSION_NAME' 作成完了"
}

# ディレクトリ作成
create_directories() {
    log_info "必要ディレクトリ作成中..."
    
    mkdir -p logs
    mkdir -p tmp
    mkdir -p instructions
    
    log_success "ディレクトリ作成完了"
}

# メイン実行
main() {
    cd "$PROJECT_ROOT"
    
    echo ""
    cleanup_existing_environment
    echo ""
    create_directories
    echo ""
    create_enhanced_worktrees
    echo ""
    create_enhanced_tmux_session
    echo ""
    
    log_success "🎉 Phase 2並列開発環境v2.0セットアップ完了！"
    echo ""
    echo "📋 次のステップ:"
    echo "1. ./scripts/start_claude_sequential.sh でClaude Code段階起動"
    echo "2. ./scripts/monitor_integration.sh で統合監視開始"
    echo "3. tmux attach-session -t $SESSION_NAME で接続"
    echo ""
    echo "🚀 効率的な並列実装をお楽しみください！"
}

main "$@" 